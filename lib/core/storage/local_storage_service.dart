import 'package:get_storage/get_storage.dart';

class LocalStorageService {
  static const String _boxName = 'subscart_storage';
  static const String _subscriptionKey = 'active_subscription';

  late final GetStorage _box;

  Future<LocalStorageService> init() async {
    await GetStorage.init(_boxName);
    _box = GetStorage(_boxName);
    return this;
  }

  Map<String, dynamic>? getSavedSubscription() {
    final data = _box.read<Map<String, dynamic>>(_subscriptionKey);
    return data;
  }

  Future<void> saveSubscription(Map<String, dynamic> json) async {
    await _box.write(_subscriptionKey, json);
  }

  Future<void> clearAll() async {
    await _box.erase();
  }
}
