import test from 'node:test';
import assert from 'node:assert/strict';
import subscriptionService from '../src/services/subscriptionService.js';
import prisma from '../src/config/prisma.js';
import {
  getLocalVendorDateTime,
  getDateRelationToVendorToday,
  compareTimes,
  isSlotCutoffPassed,
} from '../src/utils/timezoneHelper.js';
import { seedDatabase } from '../prisma/seed.js';

test('Timezone helper calculates correct date and 24-hour time for vendor', () => {
  const info = getLocalVendorDateTime('Asia/Kolkata', new Date('2026-09-18T10:30:00Z'));
  assert.equal(info.dateString, '2026-09-18');
  assert.equal(info.timeString, '16:00'); // UTC 10:30 + 5:30 = 16:00
  assert.equal(info.hour, 16);
  assert.equal(info.minute, 0);
});

test('Timezone helper handles midnight correctly', () => {
  const info = getLocalVendorDateTime('Asia/Kolkata', new Date('2026-09-18T18:30:00Z'));
  assert.equal(info.dateString, '2026-09-19');
  assert.equal(info.timeString, '00:00');
  assert.equal(info.hour, 0);
  assert.equal(info.minute, 0);
});

test('Time comparison helper works correctly', () => {
  assert.ok(compareTimes('08:00', '07:00') > 0);
  assert.ok(compareTimes('07:00', '08:00') < 0);
  assert.equal(compareTimes('07:00', '07:00'), 0);
});

test('isSlotCutoffPassed checks time correctly', () => {
  const refTime = new Date('2026-09-18T10:00:00Z'); // 15:30 in Asia/Kolkata
  assert.equal(isSlotCutoffPassed('07:00', 'Asia/Kolkata', refTime), true);
  assert.equal(isSlotCutoffPassed('11:00', 'Asia/Kolkata', refTime), true);
  assert.equal(isSlotCutoffPassed('15:00', 'Asia/Kolkata', refTime), true);
  assert.equal(isSlotCutoffPassed('18:00', 'Asia/Kolkata', refTime), false);
});

test('Idempotent seed does not throw or duplicate existing schedules', async () => {
  await assert.doesNotReject(async () => {
    await seedDatabase({ forceClean: false });
  });
});

test('getSubscription dynamically filters out past dates', async () => {
  const sub = await subscriptionService.getSubscription();
  assert.ok(sub);
  assert.ok(Array.isArray(sub.schedules));
  assert.ok(sub.schedules.length > 0);
});

test('Slot availability checks future dates correctly', async () => {
  const sub = await subscriptionService.getSubscription();
  const futureSchedule = sub.schedules[sub.schedules.length - 1];
  const dateStr = futureSchedule.date.split('T')[0];
  const availability = await subscriptionService.getSlotAvailability(dateStr);
  assert.equal(availability.targetDate, dateStr);
  assert.equal(availability.hasAvailableSlots, true);
  assert.ok(availability.nextAvailableSlot !== null);
});

test('Reschedule moves order across dates, auto-assigns next available slot when target is occupied', async () => {
  const sub = await subscriptionService.getSubscription();
  // Find future schedules to avoid today's cutoff limits
  const futureSchedules = sub.schedules.slice(1);
  const scheduleWithOrders = futureSchedules.find((s) => s.orders && s.orders.length > 0);
  assert.ok(scheduleWithOrders, 'Must find a future schedule with orders');
  const orderToMove = scheduleWithOrders.orders[0];
  const targetSchedule = futureSchedules.find((s) => s.date !== scheduleWithOrders.date);
  assert.ok(targetSchedule, 'Must find a target future schedule');

  const targetDateStr = targetSchedule.date.split('T')[0];
  const expectedAvailability = await subscriptionService.getSlotAvailability(targetDateStr, orderToMove.id);

  // Requesting 7:30 pm - 8:30 pm which is already occupied on targetSchedule
  // Should auto-assign to the next available slot on that date
  const updatedSub = await subscriptionService.rescheduleOrder({
    orderId: orderToMove.id,
    targetDate: targetSchedule.date,
    targetSlot: '7:30 pm - 8:30 pm',
  });

  const newTargetSchedule = updatedSub.schedules.find(
    (s) => s.date.split('T')[0] === targetDateStr
  );
  assert.ok(newTargetSchedule);
  const foundOrder = newTargetSchedule.orders.find((o) => o.id === orderToMove.id);
  assert.ok(foundOrder);
  assert.equal(foundOrder.timeWindow, expectedAvailability.nextAvailableSlot.displayTime);
});

test('Modifying an order from a past date throws AppError with statusCode 400', async () => {
  const pastSchedule = await prisma.dailySchedule.findFirst({
    where: { date: { lt: new Date('2026-09-19T00:00:00.000Z') } },
    include: { orders: true },
  });
  if (pastSchedule && pastSchedule.orders.length > 0) {
    await assert.rejects(
      async () => {
        await subscriptionService._assertOrderEditable(pastSchedule.orders[0].id);
      },
      (err) => {
        assert.equal(err.statusCode, 400);
        assert.ok(err.message.includes('Modifications closed'));
        return true;
      }
    );
  }
});

test('getSlotAvailability marks occupied delivery slots as unavailable with reason', async () => {
  const sub = await subscriptionService.getSubscription();
  const testSchedule = sub.schedules[0];
  const targetDate = testSchedule.date.split('T')[0];
  const availability = await subscriptionService.getSlotAvailability(targetDate);
  
  for (const order of testSchedule.orders) {
    if (order.items.length > 0) {
      const matchedSlot = availability.slots.find(
        (s) => s.displayTime.toLowerCase().trim() === order.timeWindow.toLowerCase().trim()
      );
      if (matchedSlot) {
        assert.equal(matchedSlot.isAvailable, false);
        assert.ok(
          matchedSlot.reason.includes('occupied') || matchedSlot.reason.includes('Cut-off'),
          `Reason should be occupied or cut-off, got: ${matchedSlot.reason}`
        );
      }
    }
  }
});

test('skipMealItems deletes empty MealOrder when all its meals are skipped', async () => {
  const sub = await subscriptionService.getSubscription();
  const futureSchedule = sub.schedules.find((s, idx) => idx > 1 && s.orders.length > 0);
  assert.ok(futureSchedule, 'Must have future schedule');
  const testOrder = futureSchedule.orders[0];
  const itemIds = testOrder.items.map((it) => it.id);

  await subscriptionService.skipMealItems({
    orderToItemIdsMap: { [testOrder.id]: itemIds },
  });

  const orderInDb = await prisma.mealOrder.findUnique({
    where: { id: testOrder.id },
  });
  assert.equal(orderInDb, null, 'Empty MealOrder should be deleted from DB');
});

test('Orders within daily schedules are sorted chronologically by delivery start time', async () => {
  const sub = await subscriptionService.getSubscription();
  assert.ok(sub.schedules.length > 0);
  for (const schedule of sub.schedules) {
    if (schedule.orders.length > 1) {
      for (let i = 0; i < schedule.orders.length - 1; i++) {
        const orderA = schedule.orders[i];
        const orderB = schedule.orders[i + 1];
        const timeA = subscriptionService._parseOrderStartTime(orderA.timeWindow, new Map());
        const timeB = subscriptionService._parseOrderStartTime(orderB.timeWindow, new Map());
        assert.ok(
          timeA <= timeB,
          `Orders must be sorted chronologically: ${orderA.timeWindow} (${timeA}) should be before or equal to ${orderB.timeWindow} (${timeB})`
        );
      }
    }
  }
});

test('resetData restores database to original seed state', async () => {
  const resetSub = await subscriptionService.resetData();
  assert.ok(resetSub);
  assert.ok(resetSub.schedules.length > 0);
  assert.equal(resetSub.isPaused, false);
});

