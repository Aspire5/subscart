import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const defaultOrderBox =
  'https://images.unsplash.com/photo-1615719413546-198b25453f85?w=150&auto=format&fit=crop&q=80';
const defaultVendorLogo =
  'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=150&auto=format&fit=crop&q=80';
const burgerImage =
  'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300&auto=format&fit=crop&q=80';
const saladImage =
  'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=300&auto=format&fit=crop&q=80';
const bowlImage =
  'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=300&auto=format&fit=crop&q=80';
const pastaImage =
  'https://images.unsplash.com/photo-1621996346565-e3d5d6281734?w=300&auto=format&fit=crop&q=80';
const wrapImage =
  'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=300&auto=format&fit=crop&q=80';
const juiceImage =
  'https://images.unsplash.com/photo-1613478223719-2ab802602423?w=300&auto=format&fit=crop&q=80';
const pancakeImage =
  'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=300&auto=format&fit=crop&q=80';
const salmonImage =
  'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=300&auto=format&fit=crop&q=80';

export async function seedDatabase(options = {}) {
  const { forceClean = false } = options;
  console.log(`Seeding Subscart database... (forceClean: ${forceClean})`);

  if (forceClean) {
    await prisma.mealItem.deleteMany({});
    await prisma.mealOrder.deleteMany({});
    await prisma.dailySchedule.deleteMany({});
    await prisma.deliverySlotConfig.deleteMany({});
    await prisma.vendor.deleteMany({});
  }

  // 1. Find or create Vendor
  let vendor = await prisma.vendor.findFirst();
  if (!vendor) {
    vendor = await prisma.vendor.create({
      data: {
        name: 'Daily Green & Gourmet',
        logoUrl: defaultVendorLogo,
        planName: '5-Day Lunch & Dinner Plan',
        planSummary: 'Weekly Balanced Diet • 3 Slots Daily',
        timezone: 'Asia/Kolkata',
        isPaused: false,
      },
    });
  }

  // 2. Find or create Delivery Slot Configurations
  const slotCount = await prisma.deliverySlotConfig.count({
    where: { vendorId: vendor.id },
  });

  if (slotCount === 0) {
    await prisma.deliverySlotConfig.createMany({
      data: [
        {
          vendorId: vendor.id,
          name: 'Breakfast Window',
          displayTime: '8:00 am - 9:00 am',
          startTime: '08:00',
          endTime: '09:00',
          cutoffTime: '07:00',
          cutoffNoticeTemplate: 'Edits allowed until 7:00 AM the day of your Order.',
          displayOrder: 1,
          isActive: true,
        },
        {
          vendorId: vendor.id,
          name: 'Lunch Window',
          displayTime: '12:30 pm - 1:30 pm',
          startTime: '12:30',
          endTime: '13:30',
          cutoffTime: '11:00',
          cutoffNoticeTemplate: 'Edits allowed until 11:00 AM the day of your Order.',
          displayOrder: 2,
          isActive: true,
        },
        {
          vendorId: vendor.id,
          name: 'Evening Window',
          displayTime: '4:00 pm - 5:00 pm',
          startTime: '16:00',
          endTime: '17:00',
          cutoffTime: '15:00',
          cutoffNoticeTemplate: 'Edits allowed until 3:00 PM the day of your Order.',
          displayOrder: 3,
          isActive: true,
        },
        {
          vendorId: vendor.id,
          name: 'Dinner Window',
          displayTime: '7:30 pm - 8:30 pm',
          startTime: '19:30',
          endTime: '20:30',
          cutoffTime: '18:00',
          cutoffNoticeTemplate: 'Edits allowed until 6:00 PM the day of your Order.',
          displayOrder: 4,
          isActive: true,
        },
      ],
    });
  }

  // 3. Seed Daily Schedules idempotently (Sep 14 to Sep 23, 2026)
  const baseDate = new Date(Date.UTC(2026, 8, 23)); // Sep 23, 2026 Tuesday
  const daysOffset = [-1, 0, 1, 2, 3, 4, 5, 6, 7, 8];
  const shortDayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  for (const offset of daysOffset) {
    const d = new Date(baseDate);
    d.setUTCDate(baseDate.getUTCDate() + offset);

    const dayNumber = d.getUTCDate();
    const dayOfWeek = shortDayNames[d.getUTCDay()];

    // Check if schedule for this exact vendor and date already exists
    const existingSchedule = await prisma.dailySchedule.findUnique({
      where: {
        vendorId_date: {
          vendorId: vendor.id,
          date: d,
        },
      },
    });

    if (existingSchedule) {
      console.log(`Schedule for ${d.toISOString().split('T')[0]} already exists, skipping.`);
      continue;
    }

    const schedule = await prisma.dailySchedule.create({
      data: {
        vendorId: vendor.id,
        date: d,
        dayOfWeek: dayOfWeek,
        dayNumber: dayNumber,
      },
    });

    // Orders per weekday
    switch (dayOfWeek) {
      case 'Mon':
        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 1,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '8:00 am - 9:00 am',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 7:00 AM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Greek Yogurt Berry Bowl',
                  calories: 280,
                  fatGrams: 6,
                  proteinGrams: 20,
                  carbGrams: 36,
                  imageUrl: bowlImage,
                },
                {
                  name: 'Cold Pressed Orange Juice',
                  calories: 110,
                  fatGrams: 0,
                  proteinGrams: 2,
                  carbGrams: 26,
                  imageUrl: juiceImage,
                },
              ],
            },
          },
        });

        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 2,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '12:30 pm - 1:30 pm',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 11:00 AM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Grilled Herb Chicken Bowl',
                  calories: 410,
                  fatGrams: 11,
                  proteinGrams: 38,
                  carbGrams: 42,
                  imageUrl: bowlImage,
                },
              ],
            },
          },
        });

        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 3,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '7:30 pm - 8:30 pm',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 6:00 PM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Smoked Salmon Protein Wrap',
                  calories: 380,
                  fatGrams: 14,
                  proteinGrams: 28,
                  carbGrams: 32,
                  imageUrl: wrapImage,
                },
              ],
            },
          },
        });
        break;

      case 'Tue':
        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 1,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '4:00 pm - 5:00 pm',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 3:00 PM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Grilled Chicken Burger',
                  calories: 366,
                  fatGrams: 10,
                  proteinGrams: 24,
                  carbGrams: 45,
                  imageUrl: burgerImage,
                },
                {
                  name: 'Fresh Garden Salad',
                  calories: 120,
                  fatGrams: 4,
                  proteinGrams: 3,
                  carbGrams: 16,
                  imageUrl: saladImage,
                },
              ],
            },
          },
        });

        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 2,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '12:30 pm - 1:30 pm',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 11:00 AM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Mediterranean Quinoa Bowl',
                  calories: 420,
                  fatGrams: 12,
                  proteinGrams: 18,
                  carbGrams: 52,
                  imageUrl: bowlImage,
                },
              ],
            },
          },
        });

        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 3,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '7:30 pm - 8:30 pm',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 6:00 PM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Herb Salmon Fillet',
                  calories: 440,
                  fatGrams: 18,
                  proteinGrams: 34,
                  carbGrams: 22,
                  imageUrl: salmonImage,
                },
              ],
            },
          },
        });
        break;

      case 'Wed':
        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 1,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '8:00 am - 9:00 am',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 7:00 AM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Oatmeal Chia Seed Parfait',
                  calories: 320,
                  fatGrams: 8,
                  proteinGrams: 14,
                  carbGrams: 48,
                  imageUrl: bowlImage,
                },
              ],
            },
          },
        });

        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 2,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '12:30 pm - 1:30 pm',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 11:00 AM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Wholewheat Pesto Pasta',
                  calories: 450,
                  fatGrams: 14,
                  proteinGrams: 20,
                  carbGrams: 58,
                  imageUrl: pastaImage,
                },
                {
                  name: 'Avocado Greek Salad',
                  calories: 190,
                  fatGrams: 11,
                  proteinGrams: 6,
                  carbGrams: 14,
                  imageUrl: saladImage,
                },
              ],
            },
          },
        });

        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 3,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '7:30 pm - 8:30 pm',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 6:00 PM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Lean Teriyaki Chicken Bowl',
                  calories: 395,
                  fatGrams: 8,
                  proteinGrams: 35,
                  carbGrams: 40,
                  imageUrl: bowlImage,
                },
              ],
            },
          },
        });
        break;

      case 'Thu':
        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 1,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '8:00 am - 9:00 am',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 7:00 AM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Avocado Egg Sourdough Toast',
                  calories: 350,
                  fatGrams: 15,
                  proteinGrams: 16,
                  carbGrams: 34,
                  imageUrl: burgerImage,
                },
              ],
            },
          },
        });

        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 2,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '12:30 pm - 1:30 pm',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 11:00 AM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'BBQ Paneer Power Bowl',
                  calories: 380,
                  fatGrams: 16,
                  proteinGrams: 22,
                  carbGrams: 36,
                  imageUrl: wrapImage,
                },
                {
                  name: 'Citrus Beetroot Juice',
                  calories: 95,
                  fatGrams: 0,
                  proteinGrams: 2,
                  carbGrams: 22,
                  imageUrl: juiceImage,
                },
              ],
            },
          },
        });

        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 3,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '7:30 pm - 8:30 pm',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 6:00 PM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Zucchini Pasta with Grilled Tofu',
                  calories: 320,
                  fatGrams: 9,
                  proteinGrams: 22,
                  carbGrams: 30,
                  imageUrl: pastaImage,
                },
              ],
            },
          },
        });
        break;

      case 'Fri':
        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 1,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '8:00 am - 9:00 am',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 7:00 AM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Protein Berry Pancake Stack',
                  calories: 390,
                  fatGrams: 8,
                  proteinGrams: 26,
                  carbGrams: 52,
                  imageUrl: pancakeImage,
                },
              ],
            },
          },
        });

        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 2,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '12:30 pm - 1:30 pm',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 11:00 AM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Grilled Herb Chicken Breast',
                  calories: 360,
                  fatGrams: 7,
                  proteinGrams: 42,
                  carbGrams: 18,
                  imageUrl: bowlImage,
                },
                {
                  name: 'Roasted Sweet Potato Wedges',
                  calories: 160,
                  fatGrams: 3,
                  proteinGrams: 3,
                  carbGrams: 32,
                  imageUrl: burgerImage,
                },
              ],
            },
          },
        });

        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 3,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '7:30 pm - 8:30 pm',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 6:00 PM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Tofu Veggie Stir Fry with Quinoa',
                  calories: 340,
                  fatGrams: 10,
                  proteinGrams: 20,
                  carbGrams: 44,
                  imageUrl: wrapImage,
                },
              ],
            },
          },
        });
        break;

      case 'Sat':
        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 1,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '8:00 am - 9:00 am',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 7:00 AM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Spinach Mushroom Egg Wrap',
                  calories: 310,
                  fatGrams: 12,
                  proteinGrams: 20,
                  carbGrams: 28,
                  imageUrl: wrapImage,
                },
              ],
            },
          },
        });

        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 2,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '12:30 pm - 1:30 pm',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 11:00 AM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Herb Crust Salmon Bowl',
                  calories: 440,
                  fatGrams: 16,
                  proteinGrams: 34,
                  carbGrams: 38,
                  imageUrl: salmonImage,
                },
              ],
            },
          },
        });

        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 3,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '7:30 pm - 8:30 pm',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 6:00 PM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Slow Cooked Lentil Curry Bowl',
                  calories: 375,
                  fatGrams: 9,
                  proteinGrams: 22,
                  carbGrams: 50,
                  imageUrl: bowlImage,
                },
              ],
            },
          },
        });
        break;

      case 'Sun':
      default:
        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 1,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '8:00 am - 9:00 am',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 7:00 AM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Blueberry Almond Protein Oatmeal',
                  calories: 340,
                  fatGrams: 9,
                  proteinGrams: 18,
                  carbGrams: 46,
                  imageUrl: bowlImage,
                },
              ],
            },
          },
        });

        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 2,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '12:30 pm - 1:30 pm',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 11:00 AM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Classic Lean Turkey Burger',
                  calories: 440,
                  fatGrams: 14,
                  proteinGrams: 36,
                  carbGrams: 42,
                  imageUrl: burgerImage,
                },
                {
                  name: 'Mediterranean Salad',
                  calories: 180,
                  fatGrams: 8,
                  proteinGrams: 5,
                  carbGrams: 14,
                  imageUrl: saladImage,
                },
              ],
            },
          },
        });

        await prisma.mealOrder.create({
          data: {
            scheduleId: schedule.id,
            orderNumber: 3,
            orderType: 'Delivery',
            location: 'teste',
            timeWindow: '7:30 pm - 8:30 pm',
            isSlotActive: true,
            cutoffNotice: 'Edits allowed until 6:00 PM the day of your Order.',
            previewImageUrl: defaultOrderBox,
            items: {
              create: [
                {
                  name: 'Quinoa Veggie Harvest Bowl',
                  calories: 390,
                  fatGrams: 10,
                  proteinGrams: 18,
                  carbGrams: 58,
                  imageUrl: bowlImage,
                },
              ],
            },
          },
        });
        break;
    }
  }

  console.log('Database seeded successfully.');
}

if (process.argv[1]?.endsWith('seed.js')) {
  seedDatabase()
    .catch((err) => {
      console.error('Failed to seed database:', err);
      process.exit(1);
    })
    .finally(async () => {
      await prisma.$disconnect();
    });
}
