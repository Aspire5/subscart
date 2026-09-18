import subscriptionService from '../services/subscriptionService.js';

class SubscriptionController {
  async getSubscription(req, res, next) {
    try {
      const data = await subscriptionService.getSubscription();
      res.status(200).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  }

  async getSlotAvailability(req, res, next) {
    try {
      const targetDate = req.query.targetDate || req.query.date;
      const excludeOrderId = req.query.excludeOrderId || null;
      if (!targetDate) {
        return res.status(400).json({
          success: false,
          message: 'targetDate query parameter is required (format: YYYY-MM-DD)',
        });
      }

      const availability = await subscriptionService.getSlotAvailability(targetDate, excludeOrderId);
      res.status(200).json({
        success: true,
        data: availability,
      });
    } catch (error) {
      next(error);
    }
  }

  async rescheduleOrder(req, res, next) {
    try {
      const { orderId, targetDate, targetSlot, targetSlotId } = req.body;
      if (!orderId || !targetDate) {
        return res.status(400).json({
          success: false,
          message: 'orderId and targetDate are required in the request body',
        });
      }

      const updated = await subscriptionService.rescheduleOrder({
        orderId,
        targetDate,
        targetSlot,
        targetSlotId,
      });

      res.status(200).json({
        success: true,
        message: 'Order rescheduled successfully',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  async moveMealItems(req, res, next) {
    try {
      const { sourceOrderToItemIdsMap, targetDate, targetOrderId } = req.body;
      if (!sourceOrderToItemIdsMap || !targetOrderId) {
        return res.status(400).json({
          success: false,
          message: 'sourceOrderToItemIdsMap and targetOrderId are required',
        });
      }

      const updated = await subscriptionService.moveMealItems({
        sourceOrderToItemIdsMap,
        targetDate,
        targetOrderId,
      });

      res.status(200).json({
        success: true,
        message: 'Meal items moved successfully',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  async swapMealItem(req, res, next) {
    try {
      const { sourceItemId, targetItemId } = req.body;
      if (!sourceItemId || !targetItemId) {
        return res.status(400).json({
          success: false,
          message: 'sourceItemId and targetItemId are required',
        });
      }

      const updated = await subscriptionService.swapMealItem({
        sourceItemId,
        targetItemId,
      });

      res.status(200).json({
        success: true,
        message: 'Meal items swapped successfully',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  async skipMealItems(req, res, next) {
    try {
      const { orderToItemIdsMap, itemId, orderId } = req.body;

      // Handle single item skip or batch map
      const map = orderToItemIdsMap || (orderId && itemId ? { [orderId]: [itemId] } : null);
      if (!map) {
        return res.status(400).json({
          success: false,
          message: 'orderToItemIdsMap or (orderId and itemId) is required',
        });
      }

      const updated = await subscriptionService.skipMealItems({
        orderToItemIdsMap: map,
      });

      res.status(200).json({
        success: true,
        message: 'Meal items skipped successfully',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  async toggleDeliverySlot(req, res, next) {
    try {
      const { orderId, isActive } = req.body;
      if (!orderId || typeof isActive !== 'boolean') {
        return res.status(400).json({
          success: false,
          message: 'orderId and isActive (boolean) are required',
        });
      }

      const updated = await subscriptionService.toggleDeliverySlot({
        orderId,
        isActive,
      });

      res.status(200).json({
        success: true,
        message: `Delivery slot ${isActive ? 'activated' : 'deactivated'} successfully`,
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  async togglePauseSubscription(req, res, next) {
    try {
      const { isPaused } = req.body;
      if (typeof isPaused !== 'boolean') {
        return res.status(400).json({
          success: false,
          message: 'isPaused (boolean) is required',
        });
      }

      const updated = await subscriptionService.pauseSubscription({ isPaused });
      res.status(200).json({
        success: true,
        message: `Subscription plan ${isPaused ? 'paused' : 'resumed'} successfully`,
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  async resetData(req, res, next) {
    try {
      const data = await subscriptionService.resetData();
      res.status(200).json({
        success: true,
        message: 'Database reset to initial seed data successfully',
        data,
      });
    } catch (error) {
      next(error);
    }
  }
}

export default new SubscriptionController();
