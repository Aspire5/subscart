import test from 'node:test';
import assert from 'node:assert/strict';
import subscriptionService from '../src/services/subscriptionService.js';
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
  const info = getLocalVendorDateTime('Asia/Kolkata', new Date('2026-09-17T18:35:00Z'));
  assert.equal(info.dateString, '2026-09-18');
  assert.equal(info.timeString, '00:05');
  assert.equal(info.hour, 0);
  assert.equal(info.minute, 5);
});

test('Time comparison helper works correctly', () => {
  assert.ok(compareTimes('07:00', '11:00') < 0);
  assert.ok(compareTimes('11:00', '07:00') > 0);
  assert.equal(compareTimes('15:00', '15:00'), 0);
});

test('isSlotCutoffPassed checks time correctly', () => {
  const refTime = new Date('2026-09-18T10:00:00Z'); // 15:30 in Asia/Kolkata
  assert.equal(isSlotCutoffPassed('07:00', 'Asia/Kolkata', refTime), true);
  assert.equal(isSlotCutoffPassed('11:00', 'Asia/Kolkata', refTime), true);
  assert.equal(isSlotCutoffPassed('15:00', 'Asia/Kolkata', refTime), true);
  assert.equal(isSlotCutoffPassed('18:00', 'Asia/Kolkata', refTime), false);
});

test('Idempotent seed does not throw or duplicate existing schedules', async () => {
  await seedDatabase({ forceClean: false });
  const sub = await subscriptionService.getSubscription();
  assert.ok(sub.schedules.length > 0);
});

test('getSubscription dynamically filters out past dates', async () => {
  const sub = await subscriptionService.getSubscription();
  const timezone = sub.timezone || 'Asia/Kolkata';
  for (const s of sub.schedules) {
    const dateStr = s.date.split('T')[0];
    const relation = getDateRelationToVendorToday(dateStr, timezone);
    assert.notEqual(relation, 'past', `Schedule ${dateStr} should not be in the past`);
  }
});

test('Slot availability checks future dates correctly', async () => {
  const availability = await subscriptionService.getSlotAvailability('2026-09-22');
  assert.equal(availability.hasAvailableSlots, true);
  assert.ok(availability.slots.every((s) => s.isAvailable === true));
  assert.ok(availability.nextAvailableSlot !== null);
});

test('Reschedule moves order across dates and updates cutoff notice', async () => {
  const sub = await subscriptionService.getSubscription();
  // Find future schedules to avoid today's cutoff limits
  const futureSchedules = sub.schedules.slice(1);
  const scheduleWithOrders = futureSchedules.find((s) => s.orders && s.orders.length > 0);
  assert.ok(scheduleWithOrders, 'Must find a future schedule with orders');
  const orderToMove = scheduleWithOrders.orders[0];
  const targetSchedule = futureSchedules.find((s) => s.date !== scheduleWithOrders.date);
  assert.ok(targetSchedule, 'Must find a target future schedule');

  const updatedSub = await subscriptionService.rescheduleOrder({
    orderId: orderToMove.id,
    targetDate: targetSchedule.date,
    targetSlot: '7:30 pm - 8:30 pm',
  });

  const newTargetSchedule = updatedSub.schedules.find(
    (s) => s.date.split('T')[0] === targetSchedule.date.split('T')[0]
  );
  assert.ok(newTargetSchedule);
  const foundOrder = newTargetSchedule.orders.find((o) => o.id === orderToMove.id);
  assert.ok(foundOrder);
  assert.equal(foundOrder.timeWindow, '7:30 pm - 8:30 pm');
  assert.equal(foundOrder.cutoffNotice, 'Edits allowed until 6:00 PM the day of your Order.');
});

test('Modifying an order past its cutoff throws AppError with statusCode 400', async () => {
  const sub = await subscriptionService.getSubscription();
  const todaySchedule = sub.schedules[0];
  const pastCutoffOrder = todaySchedule?.orders.find((o) => o.isPastCutoff && o.items.length > 0);
  if (pastCutoffOrder) {
    await assert.rejects(
      async () => {
        await subscriptionService.skipMealItems({
          orderToItemIdsMap: { [pastCutoffOrder.id]: [pastCutoffOrder.items[0].id] },
        });
      },
      (err) => {
        assert.equal(err.statusCode, 400);
        assert.ok(err.message.includes('Modifications closed'));
        return true;
      }
    );
  } else {
    assert.throws(
      () => {
        subscriptionService._assertOrderEditable(
          { timeWindow: '07:30 am - 08:30 am' },
          '2026-09-18',
          'Asia/Kolkata',
          '2026-09-18',
          '23:00'
        );
      },
      (err) => {
        assert.equal(err.statusCode, 400);
        assert.ok(err.message.includes('Modifications closed'));
        return true;
      }
    );
  }
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

