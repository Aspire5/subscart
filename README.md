# Subscart - Meal Plan & Subscription Management (Full-Stack Monorepo)

> 📺 **Video Walkthrough**: [**Watch the Full Video Walkthrough on Google Drive**](https://drive.google.com/file/d/10WIAfA099wkx-dpOfy6zU5ktrkroMs4n/view?usp=sharing)

A full-stack meal subscription management platform built with:
- **Frontend**: Flutter application following **Uncle Bob's Clean Architecture** and **GetX** state management.
- **Backend**: **Node.js (Express) + PostgreSQL + Prisma ORM** in a modular Layered Architecture (Routes → Controllers → Services → Data Access).

---

## 🏗️ Repository Monorepo Structure

```
subscart/
├── backend/                      # Live Node.js + PostgreSQL Backend
│   ├── .env                      # Committed deliberately for evaluator convenience
│   ├── package.json              # ES Modules ("type": "module")
│   ├── prisma/
│   │   ├── schema.prisma         # Relational schema (Vendor, DeliverySlotConfig, etc.)
│   │   └── seed.js               # Database seeder matching initial meal plans
│   ├── src/
│   │   ├── config/prisma.js      # PrismaClient connection pool singleton
│   │   ├── controllers/          # HTTP transport layer & validation
│   │   ├── routes/               # REST endpoint routes
│   │   ├── services/             # Core business logic & Prisma transactions
│   │   ├── utils/timezoneHelper.js # Vendor timezone conversions & cutoff comparison
│   │   ├── middlewares/          # Centralized error handling
│   │   └── server.js             # Express app entrypoint & health check
│   └── test/                     # Native Node.js test suite (node --test)
├── lib/                          # Flutter Client (Clean Architecture)
│   ├── core/constants/           # ApiConstants (Base URLs & endpoint routes)
│   ├── core/network/             # DioClient with smart host resolution
│   ├── data/datasources/         # SubscriptionRemoteDataSource (Live API)
│   ├── data/repositories/        # SubscriptionRepositoryImpl (Network-first + Cache)
│   ├── domain/                   # Entities, Contracts & Use Cases
│   └── presentation/             # GetX controllers, views & reusable loaders
├── test/                         # Unit tests and test doubles (fixtures)
└── README.md
```

---

## ⏰ Delivery Rescheduling & Timezone Architecture

Based on production requirements for meal delivery services:

### 1. Cross-Date Rescheduling
- Rescheduling moves the **entire delivery order** (including all paired meal items) from its current date to a **different target date** within the active subscription schedule.
- When an order is relocated, source and target day orders are automatically renumbered (1, 2, 3...).

### 2. Vendor Operational Timezone
- The vendor model has an explicit operational `timezone` (e.g., `Asia/Kolkata` or `America/New_York`).
- Regardless of the user device's local clock, all delivery cut-offs and "today" calendar checks are evaluated against the **vendor's dispatch hub timezone**.

### 3. Dynamic Database Delivery Slots (`DeliverySlotConfig`)
- Delivery windows and cut-off deadlines are **not hardcoded in code**.
- Stored in the `DeliverySlotConfig` table in PostgreSQL:
  - **Breakfast Window**: `8:00 am - 9:00 am` (Cut-off: 7:00 AM)
  - **Lunch Window**: `12:30 pm - 1:30 pm` (Cut-off: 11:00 AM)
  - **Evening Window**: `4:00 pm - 5:00 pm` (Cut-off: 3:00 PM)
  - **Dinner Window**: `7:30 pm - 8:30 pm` (Cut-off: 6:00 PM)
- Slots can be added, modified, or deactivated directly in the database without touching code.

### 4. Same-Day Cut-Off & Auto-Slot Assignment
- If a customer reschedules an order to **today**:
  - The system checks each slot's cut-off time against current vendor time.
  - Passed slots are marked unavailable and cannot be selected.
  - The system **automatically assigns the next available slot** (e.g., if Lunch cutoff has passed, Evening is auto-assigned).
  - If all cutoffs for today have passed, rescheduling to today is blocked with a clear notice directing the user to select tomorrow or later.
- For future dates, all active slots remain open.

---

## ⚡ Backend Setup & Run Instructions

> [!NOTE]
> **Environment Variables**: The `backend/.env` file is intentionally included in the repository so reviewers can clone and immediately run the backend without manual configuration.

### 1. Prerequisites
- **Node.js** `>= 18` (v20+ recommended)
- **PostgreSQL** running locally on port `5432` (or a cloud PostgreSQL URL in `.env`)

### 2. Setup Database & Start Server
```bash
# 1. Navigate to backend directory
cd backend

# 2. Install dependencies
npm install

# 3. Create the database (if not already created)
createdb subscart

# 4. Push Prisma schema to PostgreSQL
npx prisma db push

# 5. Seed the database with initial menu and delivery slot configurations
node prisma/seed.js

# 6. Start the development server
npm run dev
# Or for production:
npm start
```

The server will start at `http://localhost:3000`.

### 3. Run Backend Unit Tests
```bash
npm test
```
Tests verify timezone calculation, midnight boundaries, time comparisons, dynamic slot cutoff checks, and cross-date order movements.

---

## 🌐 API Reference

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/health` | Server health & PostgreSQL connection check |
| `GET` | `/api/subscription` | Fetch complete subscription, vendor config & daily schedules |
| `GET` | `/api/subscription/slots/availability?targetDate=YYYY-MM-DD` | Dynamic slot availability & next-available slot for target date |
| `POST` | `/api/subscription/reschedule` | Reschedule order to a different date & slot |
| `POST` | `/api/subscription/items/move` | Move meal items to another order / day |
| `POST` | `/api/subscription/items/swap` | Atomic meal item swap between orders |
| `POST` | `/api/subscription/items/skip` | Skip meal item(s) from order |
| `POST` | `/api/subscription/slot/toggle` | Activate / deactivate delivery slot |
| `POST` | `/api/subscription/pause` | Pause / resume master subscription |
| `POST` | `/api/subscription/reset` | Restore database to default initial seed data |

---

## 📱 Flutter Application Setup

### 1. Prerequisites
- Flutter SDK `^3.24.0` (Dart `^3.9.0`)
- Running backend server (`http://localhost:3000`)

### 2. Run Flutter App
```bash
# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit & widget tests
flutter test

# Launch Flutter app (macOS / Web / Simulator)
flutter run
```

### 3. API Base URL Configuration
To configure or change the backend URL, open `lib/core/constants/api_constants.dart`:
- Set `productionBaseUrl` to your deployed backend URL (e.g. Railway, AWS, Render).
- By default, it automatically resolves `http://10.0.2.2:3000/api` for Android Emulator and `http://localhost:3000/api` for iOS Simulator / macOS / Web.

---

## 🧪 Automated Testing

- **Backend**: Native Node.js test runner (`npm test`) testing timezone boundaries, slot availability, and atomic Prisma reschedule transactions.
- **Frontend**: Flutter test suite (`flutter test`) verifying all use cases, Clean Architecture repository methods, cross-date reschedule flows, and reactive GetX state management.

---

## 📄 License
This project is open-source and available under the [MIT License](LICENSE).

