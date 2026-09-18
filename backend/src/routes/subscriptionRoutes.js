import { Router } from 'express';
import subscriptionController from '../controllers/subscriptionController.js';

const router = Router();

// Subscription state & configuration
router.get('/', subscriptionController.getSubscription);
router.post('/reset', subscriptionController.resetData);
router.post('/pause', subscriptionController.togglePauseSubscription);

// Delivery slots & availability
router.get('/slots/availability', subscriptionController.getSlotAvailability);
router.post('/slot/toggle', subscriptionController.toggleDeliverySlot);

// Rescheduling & item operations
router.post('/reschedule', subscriptionController.rescheduleOrder);
router.post('/items/move', subscriptionController.moveMealItems);
router.post('/items/swap', subscriptionController.swapMealItem);
router.post('/items/skip', subscriptionController.skipMealItems);

export default router;
