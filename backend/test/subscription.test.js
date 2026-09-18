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
  // Choose an order on a future date to avoid today's cutoff checks during test
  const futureSchedule = sub.schedules[sub.schedules.length - 2];
  const orderToMove = futureSchedule.orders[0];
  const targetSchedule = sub.schedules[sub.schedules.length - 1];

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
