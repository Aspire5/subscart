class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://15.207.19.237:3000/api';

  // Endpoints
  static const String health = '/health';

  /// GET /api/subscription
  /// Fetch full active subscription plan, vendor profile, and 6-day daily schedules
  static const String subscription = '/subscription';

  /// GET /api/subscription/slots/availability?targetDate=YYYY-MM-DD
  /// Query slot availability and dynamic cut-off deadlines for a target date
  static const String slotAvailability = '/subscription/slots/availability';

  /// POST /api/subscription/reschedule
  /// Reschedule an order to a different date and/or time window
  /// Body: { "orderId": "...", "targetDate": "YYYY-MM-DD", "targetSlot": "..." }
  static const String reschedule = '/subscription/reschedule';

  /// POST /api/subscription/items/move
  /// Move selected meal items from source orders to a destination order slot
  /// Body: { "sourceOrderToItemIdsMap": {...}, "targetDate": "...", "targetOrderId": "..." }
  static const String moveItems = '/subscription/items/move';

  /// POST /api/subscription/items/swap
  /// Swap two meal items across orders or dates
  /// Body: { "sourceItemId": "...", "targetItemId": "..." }
  static const String swapItems = '/subscription/items/swap';

  /// POST /api/subscription/items/skip
  /// Skip one or multiple meal items from an order
  /// Body: { "orderId": "...", "itemId": "..." } OR { "orderToItemIdsMap": {...} }
  static const String skipItems = '/subscription/items/skip';

  /// POST /api/subscription/slot/toggle
  /// Toggle delivery slot between active and inactive
  /// Body: { "orderId": "...", "isActive": true/false }
  static const String toggleSlot = '/subscription/slot/toggle';

  /// POST /api/subscription/pause
  /// Master toggle to pause or resume the user's entire subscription
  /// Body: { "isPaused": true/false }
  static const String pause = '/subscription/pause';

  /// POST /api/subscription/reset
  /// Reset database back to default initial seed data
  static const String resetData = '/subscription/reset';
}
