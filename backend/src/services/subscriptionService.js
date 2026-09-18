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
   */
  async getSlotAvailability(targetDateInput) {
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

    const slots = vendor.slotConfigs.map((slot) => {
      let isAvailable = true;
      let reason = null;

      if (relation === 'past') {
        isAvailable = false;
        reason = 'Selected date is in the past';
      } else if (relation === 'today') {
        const isCutoffPassed = compareTimes(vendorNow.timeString, slot.cutoffTime) >= 0;
        if (isCutoffPassed) {
          isAvailable = false;
          reason = `Cut-off time (${slot.cutoffTime} in ${timezone}) has passed`;
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

    // Check slot availability for the target date
    const availability = await this.getSlotAvailability(targetDateStr);
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
          orders: true,
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
            orders: true,
          },
        });
      }

      const isSameSchedule = order.scheduleId === targetSchedule.id;

      if (isSameSchedule) {
        await tx.mealOrder.update({
          where: { id: orderId },
          data: {
            timeWindow: newTimeWindow,
            cutoffNotice: newCutoffNotice,
          },
        });
      } else {
        const nextOrderNumber = targetSchedule.orders.length + 1;

        await tx.mealOrder.update({
          where: { id: orderId },
          data: {
            scheduleId: targetSchedule.id,
            orderNumber: nextOrderNumber,
            timeWindow: newTimeWindow,
            cutoffNotice: newCutoffNotice,
          },
        });

        // Renumber remaining orders in source schedule
        const remainingSourceOrders = await tx.mealOrder.findMany({
          where: { scheduleId: order.scheduleId },
          orderBy: { orderNumber: 'asc' },
        });

        for (let i = 0; i < remainingSourceOrders.length; i++) {
          await tx.mealOrder.update({
            where: { id: remainingSourceOrders[i].id },
            data: { orderNumber: i + 1 },
          });
        }
      }
    });

    return this.getSubscription();
  }

  /**
   * Moves selected meal items from their source order(s) to a target order.
   */
  async moveMealItems({ sourceOrderToItemIdsMap, targetDate, targetOrderId }) {
    if (!sourceOrderToItemIdsMap || !targetOrderId) {
      throw new AppError('sourceOrderToItemIdsMap and targetOrderId are required', 400);
    }

    // Verify source and target orders are editable
    for (const sourceOrderId of Object.keys(sourceOrderToItemIdsMap)) {
      await this._assertOrderEditable(sourceOrderId);
    }
    await this._assertOrderEditable(targetOrderId);

    const itemIdsToMove = Object.values(sourceOrderToItemIdsMap).flat();
    if (itemIdsToMove.length === 0) {
      return this.getSubscription();
    }

    await prisma.$transaction(async (tx) => {
      await tx.mealItem.updateMany({
        where: { id: { in: itemIdsToMove } },
        data: { orderId: targetOrderId },
      });
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

    await prisma.mealItem.deleteMany({
      where: { id: { in: itemIds } },
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

        return {
          date: schedule.date.toISOString(),
          dayOfWeek: schedule.dayOfWeek,
          dayNumber: schedule.dayNumber,
          orders: schedule.orders.map((order) => {
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
