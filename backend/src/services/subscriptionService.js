import prisma from '../config/prisma.js';
import {
  getLocalVendorDateTime,
  getDateRelationToVendorToday,
  compareTimes,
  normalizeDateToUtcMidnight,
} from '../utils/timezoneHelper.js';
import { seedDatabase } from '../../prisma/seed.js';

class SubscriptionService {
  /**
   * Retrieves the active vendor and full subscription schedule.
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
      throw new Error('Vendor not configured');
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
        // Check if the cut-off time has passed in the vendor's timezone
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
    const nextAvailableSlot = availableSlots.length > 0 ? availableSlots[0] : null;

    return {
      targetDate,
      vendorTimezone: timezone,
      vendorCurrentTime: vendorNow.timeString,
      vendorCurrentDate: vendorNow.dateString,
      relation,
      hasAvailableSlots: availableSlots.length > 0,
      nextAvailableSlot,
      slots,
    };
  }

  /**
   * Reschedules an entire meal order to a different target date and time window.
   */
  async rescheduleOrder({ orderId, targetDate, targetSlot, targetSlotId }) {
    if (!orderId || !targetDate) {
      throw new Error('orderId and targetDate are required');
    }

    const order = await prisma.mealOrder.findUnique({
      where: { id: orderId },
      include: {
        schedule: {
          include: { vendor: true },
        },
      },
    });

    if (!order) {
      throw new Error(`Order with ID ${orderId} not found`);
    }

    const vendorId = order.schedule.vendorId;
    const vendor = await prisma.vendor.findUnique({
      where: { id: vendorId },
      include: {
        slotConfigs: {
          where: { isActive: true },
          orderBy: { displayOrder: 'asc' },
        },
      },
    });

    // Resolve target date in UTC midnight
    const normalizedTargetDate = normalizeDateToUtcMidnight(targetDate);
    const targetDateStr = normalizedTargetDate.toISOString().split('T')[0];

    // Check slot availability
    const availability = await this.getSlotAvailability(targetDateStr);
    if (!availability.hasAvailableSlots) {
      throw new Error(`No available delivery slots remaining on ${targetDateStr}`);
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
        // Fallback to next available slot
        selectedSlotConfig = vendor.slotConfigs.find(
          (s) => s.id === availability.nextAvailableSlot?.id
        );
      }
    }

    if (!selectedSlotConfig) {
      throw new Error('Unable to assign a valid delivery slot for the selected date');
    }

    const newTimeWindow = selectedSlotConfig.displayTime;
    const newCutoffNotice = selectedSlotConfig.cutoffNoticeTemplate;

    // Day of week and day number for target date
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const targetDayOfWeek = dayNames[normalizedTargetDate.getUTCDay()];
    const targetDayNumber = normalizedTargetDate.getUTCDate();

    // Execute atomic transaction
    await prisma.$transaction(async (tx) => {
      // Find or create target daily schedule
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

      const nextOrderNumber = targetSchedule.orders.length + 1;

      // Update the order to belong to the new schedule
      await tx.mealOrder.update({
        where: { id: orderId },
        data: {
          scheduleId: targetSchedule.id,
          orderNumber: nextOrderNumber,
          timeWindow: newTimeWindow,
          cutoffNotice: newCutoffNotice,
        },
      });

      // Re-index orders in the source schedule if it differs
      if (order.scheduleId !== targetSchedule.id) {
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
      throw new Error('sourceOrderToItemIdsMap and targetOrderId are required');
    }

    const itemIdsToMove = Object.values(sourceOrderToItemIdsMap).flat();
    if (itemIdsToMove.length === 0) {
      return this.getSubscription();
    }

    await prisma.$transaction(async (tx) => {
      // Update items to target order
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
      throw new Error('sourceItemId and targetItemId are required');
    }

    const sourceItem = await prisma.mealItem.findUnique({ where: { id: sourceItemId } });
    const targetItem = await prisma.mealItem.findUnique({ where: { id: targetItemId } });

    if (!sourceItem || !targetItem) {
      throw new Error('One or both items to swap do not exist');
    }

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
      throw new Error('orderToItemIdsMap is required');
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
      throw new Error('orderId and isActive (boolean) are required');
    }

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
      throw new Error('isPaused (boolean) is required');
    }

    const vendor = await prisma.vendor.findFirst();
    if (!vendor) {
      throw new Error('Vendor not found');
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
    await seedDatabase();
    return this.getSubscription();
  }

  /**
   * Formats the Prisma vendor aggregate into the exact JSON structure expected by the Flutter app.
   */
  _formatSubscriptionResponse(vendor) {
    return {
      vendorId: vendor.id,
      vendorName: vendor.name,
      vendorLogoUrl: vendor.logoUrl,
      planSummary: vendor.planSummary,
      planName: vendor.planName,
      timezone: vendor.timezone,
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
      schedules: vendor.schedules.map((schedule) => ({
        date: schedule.date.toISOString(),
        dayOfWeek: schedule.dayOfWeek,
        dayNumber: schedule.dayNumber,
        orders: schedule.orders.map((order) => ({
          id: order.id,
          orderNumber: order.orderNumber,
          orderType: order.orderType,
          location: order.location,
          timeWindow: order.timeWindow,
          isSlotActive: order.isSlotActive,
          cutoffNotice: order.cutoffNotice,
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
        })),
      })),
    };
  }
}

export default new SubscriptionService();
