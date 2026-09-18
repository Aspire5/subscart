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

export async function seedDatabase() {
  console.log('Seeding Subscart database...');

  // Clean existing records
  await prisma.mealItem.deleteMany({});
  await prisma.mealOrder.deleteMany({});
  await prisma.dailySchedule.deleteMany({});
  await prisma.deliverySlotConfig.deleteMany({});
  await prisma.vendor.deleteMany({});

  // 1. Create Vendor
  const vendor = await prisma.vendor.create({
    data: {
      name: 'Daily Green & Gourmet',
      logoUrl: defaultVendorLogo,
      planName: '5-Day Lunch & Dinner Plan',
      planSummary: 'Weekly Balanced Diet • 3 Slots Daily',
      timezone: 'Asia/Kolkata',
      isPaused: false,
    },
  });

  // 2. Create Dynamic Delivery Slot Configurations
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

  // 3. Create Daily Schedules (Mon Sep 14 to Sat Sep 19, 2026)
  const baseDate = new Date(Date.UTC(2026, 8, 15)); // Sep 15, 2026 Tuesday
  const daysOffset = [-1, 0, 1, 2, 3, 4];
  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  for (const offset of daysOffset) {
    const d = new Date(baseDate);
    d.setUTCDate(baseDate.getUTCDate() + offset);

    const dayNumber = d.getUTCDate();
    const dayOfWeek = dayNames[offset + 1];

    const schedule = await prisma.dailySchedule.create({
      data: {
        vendorId: vendor.id,
        date: d,
        dayOfWeek: dayOfWeek,
        dayNumber: dayNumber,
      },
    });

    // Orders for this day
    if (dayOfWeek === 'Mon') {
      // Order 1: Breakfast
      const order1 = await prisma.mealOrder.create({
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

      // Order 2: Lunch
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

      // Order 3: Dinner
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
    } else if (dayOfWeek === 'Tue') {
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
                name: 'Organic Strawberry Granola Parfait',
                calories: 310,
                fatGrams: 7,
                proteinGrams: 16,
                carbGrams: 48,
                imageUrl: bowlImage,
              },
              {
                name: 'Green Detox Cold Pressed Juice',
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
                calories: 420,
                fatGrams: 12,
                proteinGrams: 35,
                carbGrams: 45,
                imageUrl: bowlImage,
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
                name: 'Penne Arrabbiata with Basil',
                calories: 460,
                fatGrams: 9,
                proteinGrams: 14,
                carbGrams: 78,
                imageUrl: pastaImage,
              },
            ],
          },
        },
      });
    } else if (dayOfWeek === 'Wed') {
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
                name: 'Avocado Toast with Poached Egg',
                calories: 340,
                fatGrams: 18,
                proteinGrams: 14,
                carbGrams: 28,
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
                name: 'Quinoa Veggie Harvest Bowl',
                calories: 390,
                fatGrams: 10,
                proteinGrams: 18,
                carbGrams: 58,
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
                name: 'Grilled Salmon with Asparagus',
                calories: 480,
                fatGrams: 22,
                proteinGrams: 42,
                carbGrams: 12,
                imageUrl: salmonImage,
              },
            ],
          },
        },
      });
    } else if (dayOfWeek === 'Thu') {
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
                name: 'Blueberry Protein Pancake Stack',
                calories: 360,
                fatGrams: 6,
                proteinGrams: 24,
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
    } else if (dayOfWeek === 'Fri') {
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
                name: 'Penne Arrabbiata with Basil',
                calories: 460,
                fatGrams: 9,
                proteinGrams: 14,
                carbGrams: 78,
                imageUrl: pastaImage,
              },
              {
                name: 'Green Detox Cold Pressed Juice',
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
                name: 'Grilled Herb Chicken Bowl',
                calories: 420,
                fatGrams: 12,
                proteinGrams: 35,
                carbGrams: 45,
                imageUrl: bowlImage,
              },
            ],
          },
        },
      });
    } else if (dayOfWeek === 'Sat') {
      await prisma.mealOrder.create({
        data: {
          scheduleId: schedule.id,
          orderNumber: 1,
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
          orderNumber: 2,
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
    }
  }

  console.log('Database seeded successfully.');
}

if (process.argv[1].endsWith('seed.js')) {
  seedDatabase()
    .catch((err) => {
      console.error('Failed to seed database:', err);
      process.exit(1);
    })
    .finally(async () => {
      await prisma.$disconnect();
    });
}
