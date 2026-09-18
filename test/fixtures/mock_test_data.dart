import 'package:subscart/data/models/daily_schedule_model.dart';
import 'package:subscart/data/models/meal_item_model.dart';
import 'package:subscart/data/models/meal_order_model.dart';
import 'package:subscart/data/models/vendor_subscription_model.dart';

/// Test fixture data used exclusively for unit testing Clean Architecture usecases and controllers.
class MockTestData {
  MockTestData._();

  static const String defaultVendorLogo =
      'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=150&auto=format&fit=crop&q=80';
  static const String defaultOrderBox =
      'https://images.unsplash.com/photo-1615719413546-198b25453f85?w=150&auto=format&fit=crop&q=80';
  static const String burgerImage =
      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300&auto=format&fit=crop&q=80';
  static const String saladImage =
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=300&auto=format&fit=crop&q=80';
  static const String bowlImage =
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=300&auto=format&fit=crop&q=80';
  static const String pastaImage =
      'https://images.unsplash.com/photo-1621996346565-e3d5d6281734?w=300&auto=format&fit=crop&q=80';
  static const String wrapImage =
      'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=300&auto=format&fit=crop&q=80';
  static const String juiceImage =
      'https://images.unsplash.com/photo-1613478223719-2ab802602423?w=300&auto=format&fit=crop&q=80';
  static const String pancakeImage =
      'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=300&auto=format&fit=crop&q=80';
  static const String salmonImage =
      'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=300&auto=format&fit=crop&q=80';

  static VendorSubscriptionModel initialSubscription() {
    final baseDate = DateTime(2026, 9, 15); // Tuesday 15th
    final daysOffset = [-1, 0, 1, 2, 3, 4]; // Mon 14 to Sat 19

    final daysList = <DailyScheduleModel>[];

    for (final offset in daysOffset) {
      final date = baseDate.add(Duration(days: offset));
      final dayOfWeek = _getDayOfWeekShort(date.weekday);
      final dayNum = date.day;

      final List<MealOrderModel> orders;

      switch (date.weekday) {
        case DateTime.monday:
          orders = [
            MealOrderModel(
              id: 'ord_${dayNum}_1',
              orderNumber: 1,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '8:00 am - 9:00 am',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 7:00 AM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_1_1',
                  name: 'Greek Yogurt Berry Bowl',
                  calories: 280,
                  fatGrams: 6,
                  proteinGrams: 20,
                  carbGrams: 36,
                  imageUrl: bowlImage,
                ),
                MealItemModel(
                  id: 'item_${dayNum}_1_2',
                  name: 'Cold Pressed Orange Juice',
                  calories: 110,
                  fatGrams: 0,
                  proteinGrams: 2,
                  carbGrams: 26,
                  imageUrl: juiceImage,
                ),
              ],
            ),
            MealOrderModel(
              id: 'ord_${dayNum}_2',
              orderNumber: 2,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '12:30 pm - 1:30 pm',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 11:00 AM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_2_1',
                  name: 'Grilled Herb Chicken Bowl',
                  calories: 410,
                  fatGrams: 11,
                  proteinGrams: 38,
                  carbGrams: 42,
                  imageUrl: bowlImage,
                ),
              ],
            ),
            MealOrderModel(
              id: 'ord_${dayNum}_3',
              orderNumber: 3,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '7:30 pm - 8:30 pm',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 6:00 PM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_3_1',
                  name: 'Smoked Salmon Protein Wrap',
                  calories: 380,
                  fatGrams: 14,
                  proteinGrams: 28,
                  carbGrams: 32,
                  imageUrl: wrapImage,
                ),
              ],
            ),
          ];
          break;

        case DateTime.tuesday:
          orders = [
            MealOrderModel(
              id: 'ord_${dayNum}_1',
              orderNumber: 1,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '4:00 pm - 5:00 pm',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 3:00 PM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_1_1',
                  name: 'Grilled Chicken Burger',
                  calories: 366,
                  fatGrams: 10,
                  proteinGrams: 24,
                  carbGrams: 45,
                  imageUrl: burgerImage,
                ),
                MealItemModel(
                  id: 'item_${dayNum}_1_2',
                  name: 'Fresh Garden Salad',
                  calories: 120,
                  fatGrams: 4,
                  proteinGrams: 3,
                  carbGrams: 16,
                  imageUrl: saladImage,
                ),
              ],
            ),
            MealOrderModel(
              id: 'ord_${dayNum}_2',
              orderNumber: 2,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '12:30 pm - 1:30 pm',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 11:00 AM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_2_1',
                  name: 'Mediterranean Quinoa Bowl',
                  calories: 420,
                  fatGrams: 12,
                  proteinGrams: 18,
                  carbGrams: 52,
                  imageUrl: bowlImage,
                ),
              ],
            ),
            MealOrderModel(
              id: 'ord_${dayNum}_3',
              orderNumber: 3,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '7:30 pm - 8:30 pm',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 6:00 PM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_3_1',
                  name: 'Herb Salmon Fillet',
                  calories: 440,
                  fatGrams: 18,
                  proteinGrams: 34,
                  carbGrams: 22,
                  imageUrl: salmonImage,
                ),
              ],
            ),
          ];
          break;

        case DateTime.wednesday:
          orders = [
            MealOrderModel(
              id: 'ord_${dayNum}_1',
              orderNumber: 1,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '8:00 am - 9:00 am',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 7:00 AM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_1_1',
                  name: 'Oatmeal Chia Seed Parfait',
                  calories: 320,
                  fatGrams: 8,
                  proteinGrams: 14,
                  carbGrams: 48,
                  imageUrl: bowlImage,
                ),
              ],
            ),
            MealOrderModel(
              id: 'ord_${dayNum}_2',
              orderNumber: 2,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '12:30 pm - 1:30 pm',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 11:00 AM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_2_1',
                  name: 'Wholewheat Pesto Pasta',
                  calories: 450,
                  fatGrams: 14,
                  proteinGrams: 20,
                  carbGrams: 58,
                  imageUrl: pastaImage,
                ),
                MealItemModel(
                  id: 'item_${dayNum}_2_2',
                  name: 'Avocado Greek Salad',
                  calories: 190,
                  fatGrams: 11,
                  proteinGrams: 6,
                  carbGrams: 14,
                  imageUrl: saladImage,
                ),
              ],
            ),
            MealOrderModel(
              id: 'ord_${dayNum}_3',
              orderNumber: 3,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '7:30 pm - 8:30 pm',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 6:00 PM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_3_1',
                  name: 'Lean Teriyaki Chicken Bowl',
                  calories: 395,
                  fatGrams: 8,
                  proteinGrams: 35,
                  carbGrams: 40,
                  imageUrl: bowlImage,
                ),
              ],
            ),
          ];
          break;

        case DateTime.thursday:
          orders = [
            MealOrderModel(
              id: 'ord_${dayNum}_1',
              orderNumber: 1,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '8:00 am - 9:00 am',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 7:00 AM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_1_1',
                  name: 'Avocado Egg Sourdough Toast',
                  calories: 350,
                  fatGrams: 15,
                  proteinGrams: 16,
                  carbGrams: 34,
                  imageUrl: burgerImage,
                ),
              ],
            ),
            MealOrderModel(
              id: 'ord_${dayNum}_2',
              orderNumber: 2,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '12:30 pm - 1:30 pm',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 11:00 AM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_2_1',
                  name: 'BBQ Paneer Power Bowl',
                  calories: 380,
                  fatGrams: 16,
                  proteinGrams: 22,
                  carbGrams: 36,
                  imageUrl: wrapImage,
                ),
                MealItemModel(
                  id: 'item_${dayNum}_2_2',
                  name: 'Citrus Beetroot Juice',
                  calories: 95,
                  fatGrams: 0,
                  proteinGrams: 2,
                  carbGrams: 22,
                  imageUrl: juiceImage,
                ),
              ],
            ),
            MealOrderModel(
              id: 'ord_${dayNum}_3',
              orderNumber: 3,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '7:30 pm - 8:30 pm',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 6:00 PM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_3_1',
                  name: 'Zucchini Pasta with Grilled Tofu',
                  calories: 320,
                  fatGrams: 9,
                  proteinGrams: 22,
                  carbGrams: 30,
                  imageUrl: pastaImage,
                ),
              ],
            ),
          ];
          break;

        case DateTime.friday:
          orders = [
            MealOrderModel(
              id: 'ord_${dayNum}_1',
              orderNumber: 1,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '8:00 am - 9:00 am',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 7:00 AM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_1_1',
                  name: 'Protein Berry Pancake Stack',
                  calories: 390,
                  fatGrams: 8,
                  proteinGrams: 26,
                  carbGrams: 52,
                  imageUrl: pancakeImage,
                ),
              ],
            ),
            MealOrderModel(
              id: 'ord_${dayNum}_2',
              orderNumber: 2,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '12:30 pm - 1:30 pm',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 11:00 AM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_2_1',
                  name: 'Grilled Herb Chicken Breast',
                  calories: 360,
                  fatGrams: 7,
                  proteinGrams: 42,
                  carbGrams: 18,
                  imageUrl: bowlImage,
                ),
                MealItemModel(
                  id: 'item_${dayNum}_2_2',
                  name: 'Roasted Sweet Potato Wedges',
                  calories: 160,
                  fatGrams: 3,
                  proteinGrams: 3,
                  carbGrams: 32,
                  imageUrl: burgerImage,
                ),
              ],
            ),
            MealOrderModel(
              id: 'ord_${dayNum}_3',
              orderNumber: 3,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '7:30 pm - 8:30 pm',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 6:00 PM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_3_1',
                  name: 'Tofu Veggie Stir Fry with Quinoa',
                  calories: 340,
                  fatGrams: 10,
                  proteinGrams: 20,
                  carbGrams: 44,
                  imageUrl: wrapImage,
                ),
              ],
            ),
          ];
          break;

        default: // Saturday
          orders = [
            MealOrderModel(
              id: 'ord_${dayNum}_1',
              orderNumber: 1,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '9:00 am - 10:00 am',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 8:00 AM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_1_1',
                  name: 'Spinach Mushroom Egg Wrap',
                  calories: 310,
                  fatGrams: 12,
                  proteinGrams: 20,
                  carbGrams: 28,
                  imageUrl: wrapImage,
                ),
              ],
            ),
            MealOrderModel(
              id: 'ord_${dayNum}_2',
              orderNumber: 2,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '1:00 pm - 2:00 pm',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 12:00 PM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_2_1',
                  name: 'Herb Crust Salmon Bowl',
                  calories: 440,
                  fatGrams: 16,
                  proteinGrams: 34,
                  carbGrams: 38,
                  imageUrl: salmonImage,
                ),
              ],
            ),
            MealOrderModel(
              id: 'ord_${dayNum}_3',
              orderNumber: 3,
              orderType: 'Delivery',
              location: 'teste',
              timeWindow: '7:30 pm - 8:30 pm',
              isSlotActive: true,
              cutoffNotice: 'Edits allowed until 6:00 PM the day of your Order.',
              previewImageUrl: defaultOrderBox,
              items: [
                MealItemModel(
                  id: 'item_${dayNum}_3_1',
                  name: 'Slow Cooked Lentil Curry Bowl',
                  calories: 375,
                  fatGrams: 9,
                  proteinGrams: 22,
                  carbGrams: 50,
                  imageUrl: bowlImage,
                ),
              ],
            ),
          ];
      }

      daysList.add(
        DailyScheduleModel(
          date: date,
          dayOfWeek: dayOfWeek,
          dayNumber: date.day,
          orders: orders,
        ),
      );
    }

    return VendorSubscriptionModel(
      vendorId: 'vendor_healthy_lab_01',
      vendorName: 'Healthy Lab ...',
      vendorLogoUrl: defaultVendorLogo,
      planSummary: 'Fri 3 Meals • Healthy Plan- 6 ...',
      planName: 'Healthy Plan - 3x Day',
      isPaused: false,
      schedules: daysList,
    );
  }

  static String _getDayOfWeekShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }

  static List<MealItemModel> alternateMealsPool() {
    return const [
      MealItemModel(
        id: 'pool_1',
        name: 'Avocado Greek Salad',
        calories: 310,
        fatGrams: 15,
        proteinGrams: 12,
        carbGrams: 22,
        imageUrl: saladImage,
      ),
      MealItemModel(
        id: 'pool_2',
        name: 'Wholewheat Pesto Pasta',
        calories: 450,
        fatGrams: 14,
        proteinGrams: 20,
        carbGrams: 58,
        imageUrl: pastaImage,
      ),
      MealItemModel(
        id: 'pool_3',
        name: 'Lean Teriyaki Chicken',
        calories: 395,
        fatGrams: 8,
        proteinGrams: 35,
        carbGrams: 40,
        imageUrl: bowlImage,
      ),
      MealItemModel(
        id: 'pool_4',
        name: 'BBQ Paneer Power Bowl',
        calories: 380,
        fatGrams: 16,
        proteinGrams: 22,
        carbGrams: 36,
        imageUrl: wrapImage,
      ),
      MealItemModel(
        id: 'pool_5',
        name: 'Herb Salmon Fillet',
        calories: 440,
        fatGrams: 18,
        proteinGrams: 34,
        carbGrams: 22,
        imageUrl: salmonImage,
      ),
      MealItemModel(
        id: 'pool_6',
        name: 'Protein Berry Pancake Stack',
        calories: 390,
        fatGrams: 8,
        proteinGrams: 26,
        carbGrams: 52,
        imageUrl: pancakeImage,
      ),
    ];
  }
}
