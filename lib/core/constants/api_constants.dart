import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized API configuration for Subscart.
/// Base URLs and all backend endpoints are defined here for easy editing.
class ApiConstants {
  ApiConstants._();

  // ===========================================================================
  // 1. BASE URL CONFIGURATION (Edit this section to switch environments)
  // ===========================================================================

  /// Set this to your live production backend URL (e.g., Railway, AWS, Render).
  /// If set, the app will always prioritize this over localhost URLs.
  ///
  /// Examples:
  ///   'https://subscart-backend.up.railway.app/api'
  ///   'https://api.yourdomain.com/api'
  ///   'http://15.207.19.237:3000/api' (AWS EC2 deployment)
  static const String productionBaseUrl = 'http://15.207.19.237:3000/api';

  /// Android Emulator requires '10.0.2.2' to access host machine's localhost.
  static const String localAndroidBaseUrl = 'http://10.0.2.2:3000/api';

  /// iOS Simulator, macOS Desktop, and Web connect directly to 'localhost'.
  static const String localDefaultBaseUrl = 'http://localhost:3000/api';

  /// Resolves the active Base URL automatically based on runtime platform.
  static String get baseUrl {
    if (productionBaseUrl.trim().isNotEmpty) {
      return productionBaseUrl.trim();
    }
    if (!kIsWeb && Platform.isAndroid) {
      return localAndroidBaseUrl;
    }
    return localDefaultBaseUrl;
  }

  // ===========================================================================
  // 2. API ENDPOINTS (Node.js / Express Backend Routes)
  // ===========================================================================

  /// GET /api/health
  /// Server and database connection status check
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
