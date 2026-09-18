import prisma from '../config/prisma.js';
import {
  getLocalVendorDateTime,
  getDateRelationToVendorToday,
  compareTimes,
  normalizeDateToUtcMidnight,
  getTimezoneDisplay,
} from '../utils/timezoneHelper.js';
import { AppError } from '../utils/errors.js';
import { seedDatabase } from '../../prisma/seed.js';

class SubscriptionService {
  /**
   * Asserts that an order is eligible for modifications:
   * 1. Not from a past date.
   * 2. If today, its delivery window cutoff time has not passed.
   * Throws an AppError(..., 400) if cutoff has passed.
   */
  async _assertOrderEditable(orderId) {
    const order = await prisma.mealOrder.findUnique({
      where: { id: orderId },
      include: {
        schedule: {
          include: {
            vendor: {
              include: {
                slotConfigs: { where: { isActive: true } },
              },
            },
          },
        },
      },
    });

    if (!order) {
      throw new AppError(`Order with ID ${orderId} not found`, 404);
    }

    const vendor = order.schedule.vendor;
    const timezone = vendor.timezone || 'Asia/Kolkata';
    const scheduleDateStr = order.schedule.date.toISOString().split('T')[0];
    const relation = getDateRelationToVendorToday(scheduleDateStr, timezone);

    if (relation === 'past') {
      throw new AppError('Modifications closed: Cannot edit an order from a past date', 400);
    }

    if (relation === 'today') {
      const vendorNow = getLocalVendorDateTime(timezone);
      const matchedSlot = vendor.slotConfigs.find(
        (s) =>
          s.displayTime.toLowerCase() === order.timeWindow.toLowerCase() ||
          s.name.toLowerCase() === order.timeWindow.toLowerCase()
      );
      if (matchedSlot && compareTimes(vendorNow.timeString, matchedSlot.cutoffTime) >= 0) {
        throw new AppError(
          `Modifications closed: Cut-off time (${matchedSlot.cutoffTime}) has passed for this delivery window`,
          400
        );
      }
    }

    return order;
  }

  /**
   * Retrieves the active vendor and full subscription schedule, filtering out past dates.
   */
  async getSubscription() {
    let vendor = await prisma.vendor.findFirst({
      include: {
        slotConfigs: {
          where: { isActive: true },
          orderBy: { displayOrder: 'asc' },
        },
        schedules: {
          orderBy: { date: 'asc' },
          include: {
            orders: {
              orderBy: { orderNumber: 'asc' },
              include: {
                items: {
                  orderBy: { createdAt: 'asc' },
                },
              },
            },
          },
        },
      },
    });

    if (!vendor) {
      await seedDatabase();
      return this.getSubscription();
    }

    return this._formatSubscriptionResponse(vendor);
  }

  /**
   * Evaluates delivery slot availability for a given target date against the vendor's local timezone.
   * Also checks for slot collisions (existing active orders with items on that date).
   */
  async getSlotAvailability(targetDateInput, excludeOrderId = null) {
    const vendor = await prisma.vendor.findFirst({
      include: {
        slotConfigs: {
          where: { isActive: true },
          orderBy: { displayOrder: 'asc' },
        },
      },
    });

    if (!vendor) {
      throw new AppError('Vendor not configured', 500);
    }

    const timezone = vendor.timezone || 'Asia/Kolkata';
    const targetDate = typeof targetDateInput === 'string'
      ? targetDateInput.split('T')[0]
      : targetDateInput.toISOString().split('T')[0];

    const vendorNow = getLocalVendorDateTime(timezone);
    const relation = getDateRelationToVendorToday(targetDate, timezone);

    // Check existing schedule for this target date to detect occupied slots
    const normalizedTargetDate = normalizeDateToUtcMidnight(targetDate);
    const existingSchedule = await prisma.dailySchedule.findUnique({
      where: {
        vendorId_date: {
          vendorId: vendor.id,
          date: normalizedTargetDate,
        },
      },
      include: {
        orders: {
          include: {
            items: true,
          },
        },
      },
    });

    const occupiedWindows = new Set();
    let currentOrderWindow = null;
    if (existingSchedule && existingSchedule.orders) {
      for (const ord of existingSchedule.orders) {
        if (excludeOrderId && ord.id === excludeOrderId) {
          currentOrderWindow = ord.timeWindow.toLowerCase().trim();
          continue;
        }
        if (ord.items && ord.items.length > 0) {
          occupiedWindows.add(ord.timeWindow.toLowerCase().trim());
        }
      }
    }

    const slots = vendor.slotConfigs.map((slot) => {
      let isAvailable = true;
      let isCurrentSlot = false;
      let reason = null;

      if (
        currentOrderWindow &&
        (currentOrderWindow === slot.displayTime.toLowerCase().trim() ||
          currentOrderWindow === slot.name.toLowerCase().trim())
      ) {
        isAvailable = false;
        isCurrentSlot = true;
        reason = 'Current delivery window';
      } else if (relation === 'past') {
        isAvailable = false;
        reason = 'Selected date is in the past';
      } else if (relation === 'today') {
        const isCutoffPassed = compareTimes(vendorNow.timeString, slot.cutoffTime) >= 0;
        if (isCutoffPassed) {
          isAvailable = false;
          reason = `Cut-off time (${slot.cutoffTime} in ${timezone}) has passed`;
        }
      }

      if (isAvailable) {
        const isOccupied = occupiedWindows.has(slot.displayTime.toLowerCase().trim()) ||
                           occupiedWindows.has(slot.name.toLowerCase().trim());
        if (isOccupied) {
          isAvailable = false;
          reason = 'Slot occupied by an existing order';
        }
      }

      return {
        id: slot.id,
        name: slot.name,
        displayTime: slot.displayTime,
        startTime: slot.startTime,
        endTime: slot.endTime,
        cutoffTime: slot.cutoffTime,
        cutoffNotice: slot.cutoffNoticeTemplate,
        displayOrder: slot.displayOrder,
        isAvailable,
        isCurrentSlot,
        reason,
      };
    });

    const availableSlots = slots.filter((s) => s.isAvailable);
    const hasAvailableSlots = availableSlots.length > 0;
    const nextAvailableSlot = hasAvailableSlots ? availableSlots[0] : null;

    return {
      targetDate,
      vendorTimezone: timezone,
      vendorCurrentTime: vendorNow.timeString,
      hasAvailableSlots,
      nextAvailableSlot: nextAvailableSlot
        ? {
            id: nextAvailableSlot.id,
            name: nextAvailableSlot.name,
            displayTime: nextAvailableSlot.displayTime,
            cutoffTime: nextAvailableSlot.cutoffTime,
            cutoffNotice: nextAvailableSlot.cutoffNotice,
          }
        : null,
      slots,
    };
  }

  /**
   * Re-indexes orderNumber for all orders in a DailySchedule chronologically (1..N).
   */
  async _normalizeScheduleOrders(tx, scheduleId) {
    if (!scheduleId) return;

    const orders = await tx.mealOrder.findMany({
      where: { scheduleId },
      include: { items: true },
    });

    if (orders.length === 0) return;

    const parseStartMinutes = (timeWindow) => {
      if (!timeWindow) return 0;
      const startPart = timeWindow.split('-')[0].trim().toLowerCase();
      const match = startPart.match(/^(\d+)(?::(\d+))?\s*(am|pm)?$/i);
      if (!match) return 0;
      let hour = parseInt(match[1], 10);
      const min = match[2] ? parseInt(match[2], 10) : 0;
      const meridiem = match[3];
      if (meridiem === 'pm' && hour < 12) hour += 12;
      if (meridiem === 'am' && hour === 12) hour = 0;
      return hour * 60 + min;
    };

    orders.sort((a, b) => {
      const minA = parseStartMinutes(a.timeWindow);
      const minB = parseStartMinutes(b.timeWindow);
      return minA - minB || a.orderNumber - b.orderNumber;
    });

    for (let i = 0; i < orders.length; i++) {
      await tx.mealOrder.update({
        where: { id: orders[i].id },
        data: { orderNumber: 1000 + i },
      });
    }

    for (let i = 0; i < orders.length; i++) {
      await tx.mealOrder.update({
        where: { id: orders[i].id },
        data: { orderNumber: i + 1 },
      });
    }
  }

  /**
   * Reschedules an order to a target date and delivery slot with transactional safety.
   */
  async rescheduleOrder({ orderId, targetDate, targetSlot, targetSlotId }) {
    if (!orderId || !targetDate) {
      throw new AppError('orderId and targetDate are required', 400);
    }

    // Assert source order is editable
    const order = await this._assertOrderEditable(orderId);
    const vendorId = order.schedule.vendorId;
    const vendor = order.schedule.vendor;

    // Resolve target date in UTC midnight
    const normalizedTargetDate = normalizeDateToUtcMidnight(targetDate);
    const targetDateStr = normalizedTargetDate.toISOString().split('T')[0];

    // Check slot availability for the target date, excluding current order in case it was already on this date
    const availability = await this.getSlotAvailability(targetDateStr, orderId);
    if (!availability.hasAvailableSlots) {
      throw new AppError(`No available delivery slots remaining on ${targetDateStr}`, 400);
    }

    // Determine target slot config
    let selectedSlotConfig = null;
    if (targetSlotId) {
      selectedSlotConfig = vendor.slotConfigs.find((s) => s.id === targetSlotId);
    } else if (targetSlot) {
      selectedSlotConfig = vendor.slotConfigs.find(
        (s) => s.displayTime.toLowerCase() === targetSlot.toLowerCase() ||
               s.name.toLowerCase() === targetSlot.toLowerCase()
      );
    }

    // Guard against self-reschedule (same date & same delivery window)
    const orderScheduleDateStr = order.schedule.date.toISOString().split('T')[0];
    if (orderScheduleDateStr === targetDateStr && selectedSlotConfig) {
      const isCurrentWindow =
        selectedSlotConfig.displayTime.toLowerCase().trim() === order.timeWindow.toLowerCase().trim() ||
        selectedSlotConfig.name.toLowerCase().trim() === order.timeWindow.toLowerCase().trim();
      if (isCurrentWindow) {
        throw new AppError('Order is already scheduled for this delivery window', 400);
      }
    }

    // If requested slot is invalid or unavailable for today, use next available slot
    if (!selectedSlotConfig) {
      selectedSlotConfig = vendor.slotConfigs.find(
        (s) => s.id === availability.nextAvailableSlot?.id
      );
    } else {
      const slotStatus = availability.slots.find((s) => s.id === selectedSlotConfig.id);
      if (slotStatus && !slotStatus.isAvailable) {
        selectedSlotConfig = vendor.slotConfigs.find(
          (s) => s.id === availability.nextAvailableSlot?.id
        );
      }
    }

    if (!selectedSlotConfig) {
      throw new AppError('Unable to assign a valid delivery slot for the selected date', 400);
    }

    const newTimeWindow = selectedSlotConfig.displayTime;
    const newCutoffNotice = selectedSlotConfig.cutoffNoticeTemplate;

    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const targetDayOfWeek = dayNames[normalizedTargetDate.getUTCDay()];
    const targetDayNumber = normalizedTargetDate.getUTCDate();
    const sourceScheduleId = order.scheduleId;

    // Execute atomic transaction
    await prisma.$transaction(async (tx) => {
      let targetSchedule = await tx.dailySchedule.findUnique({
        where: {
          vendorId_date: {
            vendorId: vendorId,
            date: normalizedTargetDate,
          },
        },
        include: {
          orders: {
            include: {
              items: true,
            },
          },
        },
      });

      if (!targetSchedule) {
        targetSchedule = await tx.dailySchedule.create({
          data: {
            vendorId: vendorId,
            date: normalizedTargetDate,
            dayOfWeek: targetDayOfWeek,
            dayNumber: targetDayNumber,
          },
          include: {
            orders: {
              include: {
                items: true,
              },
            },
          },
        });
      }

      // Check if target schedule has an occupied slot (another order with items > 0)
      const existingConflict = targetSchedule.orders.find(
        (o) =>
          o.id !== orderId &&
          o.timeWindow.toLowerCase().trim() === newTimeWindow.toLowerCase().trim() &&
          o.items &&
          o.items.length > 0
      );
      if (existingConflict) {
        throw new AppError(
          `Delivery slot ${newTimeWindow} is already occupied on ${targetDateStr}`,
          400
        );
      }

      // Reassign order to target schedule with updated window
      await tx.mealOrder.update({
        where: { id: orderId },
        data: {
          scheduleId: targetSchedule.id,
          orderNumber: 5000,
          timeWindow: newTimeWindow,
          cutoffNotice: newCutoffNotice,
        },
      });

      // Renormalize orders on source and target schedules
      if (sourceScheduleId && sourceScheduleId !== targetSchedule.id) {
        await this._normalizeScheduleOrders(tx, sourceScheduleId);
      }
      await this._normalizeScheduleOrders(tx, targetSchedule.id);
    });

    return this.getSubscription();
  }

  /**
   * Moves selected meal items from their source order(s) to a target order.
   * Dynamically provisions target order on targetDate if not existing.
   */
  async moveMealItems({ sourceOrderToItemIdsMap, targetDate, targetOrderId, targetOrderNumber }) {
    if (!sourceOrderToItemIdsMap) {
      throw new AppError('sourceOrderToItemIdsMap is required', 400);
    }

    // Verify source and target orders are editable
    for (const sourceOrderId of Object.keys(sourceOrderToItemIdsMap)) {
      await this._assertOrderEditable(sourceOrderId);
    }

    const itemIdsToMove = Object.values(sourceOrderToItemIdsMap).flat();
    if (itemIdsToMove.length === 0) {
      return this.getSubscription();
    }

    await prisma.$transaction(async (tx) => {
      let resolvedTargetOrderId = targetOrderId;

      if (resolvedTargetOrderId) {
        const targetOrder = await tx.mealOrder.findUnique({
          where: { id: resolvedTargetOrderId },
        });
        if (!targetOrder) {
          resolvedTargetOrderId = null;
        } else {
          await this._assertOrderEditable(resolvedTargetOrderId);
        }
      }

      // If no valid targetOrderId, resolve or dynamically create target order on targetDate
      if (!resolvedTargetOrderId) {
        if (!targetDate) {
          throw new AppError('targetOrderId or targetDate with slot is required', 400);
        }

        const normalizedTargetDate = normalizeDateToUtcMidnight(targetDate);
        const firstSourceOrderId = Object.keys(sourceOrderToItemIdsMap)[0];
        const sampleOrder = await tx.mealOrder.findUnique({
          where: { id: firstSourceOrderId },
          include: {
            schedule: {
              include: {
                vendor: {
                  include: {
                    slotConfigs: {
                      where: { isActive: true },
                      orderBy: { displayOrder: 'asc' },
                    },
                  },
                },
              },
            },
          },
        });

        const vendor = sampleOrder.schedule.vendor;
        const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        const targetDayOfWeek = dayNames[normalizedTargetDate.getUTCDay()];
        const targetDayNumber = normalizedTargetDate.getUTCDate();

        let targetSchedule = await tx.dailySchedule.findUnique({
          where: {
            vendorId_date: {
              vendorId: vendor.id,
              date: normalizedTargetDate,
            },
          },
          include: { orders: true },
        });

        if (!targetSchedule) {
          targetSchedule = await tx.dailySchedule.create({
            data: {
              vendorId: vendor.id,
              date: normalizedTargetDate,
              dayOfWeek: targetDayOfWeek,
              dayNumber: targetDayNumber,
            },
            include: { orders: true },
          });
        }

        const desiredOrderNum = targetOrderNumber ? parseInt(targetOrderNumber, 10) : 1;
        let existingOrder = targetSchedule.orders.find((o) => o.orderNumber === desiredOrderNum);

        if (!existingOrder) {
          const slotConfig = vendor.slotConfigs[desiredOrderNum - 1] || vendor.slotConfigs[0];
          existingOrder = await tx.mealOrder.create({
            data: {
              scheduleId: targetSchedule.id,
              orderNumber: desiredOrderNum,
              timeWindow: slotConfig.displayTime,
              cutoffNotice: slotConfig.cutoffNoticeTemplate,
              isSlotActive: true,
            },
          });
        }

        resolvedTargetOrderId = existingOrder.id;
        await this._assertOrderEditable(resolvedTargetOrderId);
      }

      await tx.mealItem.updateMany({
        where: { id: { in: itemIdsToMove } },
        data: { orderId: resolvedTargetOrderId },
      });

      // Check affected source orders - if an order has 0 items remaining, auto-remove empty MealOrder
      const affectedScheduleIds = new Set();
      for (const sourceOrderId of Object.keys(sourceOrderToItemIdsMap)) {
        const remainingCount = await tx.mealItem.count({
          where: { orderId: sourceOrderId },
        });
        const srcOrder = await tx.mealOrder.findUnique({ where: { id: sourceOrderId } });
        if (srcOrder) {
          affectedScheduleIds.add(srcOrder.scheduleId);
          if (remainingCount === 0) {
            await tx.mealOrder.delete({
              where: { id: sourceOrderId },
            });
          }
        }
      }

      const targetOrder = await tx.mealOrder.findUnique({ where: { id: resolvedTargetOrderId } });
      if (targetOrder) {
        affectedScheduleIds.add(targetOrder.scheduleId);
      }

      for (const scheduleId of affectedScheduleIds) {
        await this._normalizeScheduleOrders(tx, scheduleId);
      }
    });

    return this.getSubscription();
  }

  /**
   * Swaps two meal items across orders or dates.
   */
  async swapMealItem({ sourceItemId, targetItemId }) {
    if (!sourceItemId || !targetItemId) {
      throw new AppError('sourceItemId and targetItemId are required', 400);
    }

    const sourceItem = await prisma.mealItem.findUnique({
      where: { id: sourceItemId },
      include: { order: true },
    });
    const targetItem = await prisma.mealItem.findUnique({
      where: { id: targetItemId },
      include: { order: true },
    });

    if (!sourceItem || !targetItem) {
      throw new AppError('One or both items to swap do not exist', 404);
    }

    await this._assertOrderEditable(sourceItem.orderId);
    await this._assertOrderEditable(targetItem.orderId);

    await prisma.$transaction(async (tx) => {
      await tx.mealItem.update({
        where: { id: sourceItemId },
        data: { orderId: targetItem.orderId },
      });

      await tx.mealItem.update({
        where: { id: targetItemId },
        data: { orderId: sourceItem.orderId },
      });
    });

    return this.getSubscription();
  }

  /**
   * Skips (removes) meal items from an order.
   * If all items in an order are removed, automatically removes the empty MealOrder.
   */
  async skipMealItems({ orderToItemIdsMap }) {
    if (!orderToItemIdsMap) {
      throw new AppError('orderToItemIdsMap is required', 400);
    }

    for (const orderId of Object.keys(orderToItemIdsMap)) {
      await this._assertOrderEditable(orderId);
    }

    const itemIds = Object.values(orderToItemIdsMap).flat();
    if (itemIds.length === 0) {
      return this.getSubscription();
    }

    await prisma.$transaction(async (tx) => {
      await tx.mealItem.deleteMany({
        where: { id: { in: itemIds } },
      });

      // Check affected orders - if an order has 0 items remaining, auto-remove the empty MealOrder
      const affectedOrderIds = Object.keys(orderToItemIdsMap);
      const affectedScheduleIds = new Set();
      for (const orderId of affectedOrderIds) {
        const order = await tx.mealOrder.findUnique({ where: { id: orderId } });
        if (order) {
          affectedScheduleIds.add(order.scheduleId);
        }
        const remainingCount = await tx.mealItem.count({
          where: { orderId },
        });
        if (remainingCount === 0) {
          await tx.mealOrder.delete({
            where: { id: orderId },
          });
        }
      }

      for (const scheduleId of affectedScheduleIds) {
        await this._normalizeScheduleOrders(tx, scheduleId);
      }
    });

    return this.getSubscription();
  }

  /**
   * Toggles active delivery state for a specific order slot.
   */
  async toggleDeliverySlot({ orderId, isActive }) {
    if (!orderId || typeof isActive !== 'boolean') {
      throw new AppError('orderId and isActive (boolean) are required', 400);
    }

    await this._assertOrderEditable(orderId);

    await prisma.mealOrder.update({
      where: { id: orderId },
      data: { isSlotActive: isActive },
    });

    return this.getSubscription();
  }

  /**
   * Pauses or resumes the entire subscription plan.
   */
  async pauseSubscription({ isPaused }) {
    if (typeof isPaused !== 'boolean') {
      throw new AppError('isPaused (boolean) is required', 400);
    }

    const vendor = await prisma.vendor.findFirst();
    if (!vendor) {
      throw new AppError('Vendor not found', 404);
    }

    await prisma.vendor.update({
      where: { id: vendor.id },
      data: { isPaused },
    });

    return this.getSubscription();
  }

  /**
   * Resets database back to default seed data for demonstration.
   */
  async resetData() {
    await seedDatabase({ forceClean: true });
    return this.getSubscription();
  }

  /**
   * Helper to determine normalized 24-hour start time for chronological sorting.
   */
  _parseOrderStartTime(timeWindow, slotMap) {
    if (!timeWindow) return '99:99';
    const matched = slotMap.get(timeWindow.toLowerCase().trim());
    if (matched?.startTime) return matched.startTime;
    const match = timeWindow.toLowerCase().match(/(\d+):?(\d+)?\s*(am|pm)/);
    if (match) {
      let h = parseInt(match[1], 10);
      const m = match[2] ? parseInt(match[2], 10) : 0;
      if (match[3] === 'pm' && h < 12) h += 12;
      if (match[3] === 'am' && h === 12) h = 0;
      return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
    }
    return '99:99';
  }

  /**
   * Formats the Prisma vendor aggregate into the exact JSON structure expected by the Flutter app.
   * Filters out past dates and flags today's orders whose cutoff has passed.
   */
  _formatSubscriptionResponse(vendor) {
    const timezone = vendor.timezone || 'Asia/Kolkata';
    const vendorNow = getLocalVendorDateTime(timezone);

    // Filter out past schedules dynamically
    const upcomingSchedules = vendor.schedules.filter((schedule) => {
      const scheduleDateStr = schedule.date.toISOString().split('T')[0];
      return getDateRelationToVendorToday(scheduleDateStr, timezone) !== 'past';
    });

    // Create lookup map for slot cutoff times
    const slotMap = new Map();
    for (const slot of vendor.slotConfigs) {
      slotMap.set(slot.displayTime.toLowerCase(), slot);
      slotMap.set(slot.name.toLowerCase(), slot);
    }

    return {
      vendorId: vendor.id,
      vendorName: vendor.name,
      vendorLogoUrl: vendor.logoUrl,
      planSummary: vendor.planSummary,
      planName: vendor.planName,
      timezone: vendor.timezone,
      timezoneDisplay: getTimezoneDisplay(vendor.timezone),
      isPaused: vendor.isPaused,
      availableSlots: vendor.slotConfigs.map((slot) => ({
        id: slot.id,
        name: slot.name,
        displayTime: slot.displayTime,
        startTime: slot.startTime,
        endTime: slot.endTime,
        cutoffTime: slot.cutoffTime,
        cutoffNotice: slot.cutoffNoticeTemplate,
        displayOrder: slot.displayOrder,
      })),
      schedules: upcomingSchedules.map((schedule) => {
        const scheduleDateStr = schedule.date.toISOString().split('T')[0];
        const isToday = getDateRelationToVendorToday(scheduleDateStr, timezone) === 'today';

        // Sort orders chronologically by slot delivery start time
        const sortedOrders = [...schedule.orders].sort((a, b) => {
          const timeA = this._parseOrderStartTime(a.timeWindow, slotMap);
          const timeB = this._parseOrderStartTime(b.timeWindow, slotMap);
          return timeA.localeCompare(timeB) || (a.orderNumber - b.orderNumber);
        });

        return {
          date: schedule.date.toISOString(),
          dayOfWeek: schedule.dayOfWeek,
          dayNumber: schedule.dayNumber,
          orders: sortedOrders.map((order) => {
            let isPastCutoff = false;
            let displayCutoffNotice = order.cutoffNotice;

            if (isToday) {
              const matchedSlot = slotMap.get(order.timeWindow.toLowerCase());
              const cutoffTime = matchedSlot?.cutoffTime;
              if (cutoffTime && compareTimes(vendorNow.timeString, cutoffTime) >= 0) {
                isPastCutoff = true;
                displayCutoffNotice = 'Cut-off passed • Order in preparation';
              }
            }

            return {
              id: order.id,
              orderNumber: order.orderNumber,
              orderType: order.orderType,
              location: order.location,
              timeWindow: order.timeWindow,
              isSlotActive: order.isSlotActive,
              cutoffNotice: displayCutoffNotice,
              isPastCutoff,
              previewImageUrl: order.previewImageUrl,
              items: order.items.map((item) => ({
                id: item.id,
                name: item.name,
                calories: item.calories,
                fatGrams: item.fatGrams,
                proteinGrams: item.proteinGrams,
                carbGrams: item.carbGrams,
                imageUrl: item.imageUrl,
              })),
            };
          }),
        };
      }),
    };
  }
}

export default new SubscriptionService();
