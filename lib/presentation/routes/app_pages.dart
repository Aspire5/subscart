import 'package:get/get.dart';
import '../bindings/schedule_binding.dart';
import '../views/schedule_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.schedule;

  static final routes = [
    GetPage(
      name: AppRoutes.schedule,
      page: () => const ScheduleView(),
      binding: ScheduleBinding(),
      transition: Transition.fadeIn,
    ),
  ];
}
