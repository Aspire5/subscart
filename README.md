# Subscart - Meal Plan & Subscription Management (Full-Stack Monorepo)

> 📺 **Video Walkthrough**: [**Watch the Full Video Walkthrough on Google Drive**](https://drive.google.com/file/d/10WIAfA099wkx-dpOfy6zU5ktrkroMs4n/view?usp=sharing)

Subscart is an enterprise-grade full-stack meal subscription management platform designed for real-world recurring delivery services. It handles dynamic delivery slots, strict kitchen cut-off deadlines, cross-date rescheduling, pairwise swaps, multi-item batch movements, and ghost-order elimination.

- **Frontend**: Flutter application architected with **Uncle Bob’s Clean Architecture** (Domain, Data, Presentation) and **GetX** reactive state management.
- **Backend**: **Node.js (Express) + PostgreSQL + Prisma ORM** in a modular Layered Architecture (Routes → Controllers → Services → Data Access).
- **Database**: PostgreSQL with dynamic vendor delivery window configurations and atomic ACID transactions.

---

## 🏗️ Repository Architecture & Directory Structure

```
subscart/
├── backend/                          # Node.js + Express + Prisma + PostgreSQL Backend
│   ├── .env                          # Pre-configured environment file for instant evaluator setup
│   ├── package.json                  # ES Modules ("type": "module")
│   ├── prisma/
│   │   ├── schema.prisma             # Relational data models (Vendor, SlotConfig, Schedule, Order, Item)
│   │   └── seed.js                   # Idempotent database seeder with realistic meal plans
│   ├── src/
│   │   ├── config/prisma.js          # PrismaClient singleton with pooled connections
│   │   ├── controllers/              # HTTP transport controllers & parameter validation
│   │   ├── routes/                   # REST routing definitions
│   │   ├── services/                 # Core domain logic & atomic Prisma $transactions
│   │   ├── utils/timezoneHelper.js   # Vendor operational timezone calculation engine
│   │   ├── middlewares/              # Global error handling and logging
│   │   └── server.js                 # Express server bootstrap & health check
│   └── test/                         # Native Node.js test suite (node --test)
├── lib/                              # Flutter Client (Clean Architecture)
│   ├── core/                         # Constants, theme tokens, network client & date utilities
│   │   ├── constants/api_constants.dart  # Smart host resolution (localhost vs 10.0.2.2)
│   │   ├── network/dio_client.dart       # Dio instance with logging & interceptors
│   │   └── theme/                    # Semantic design tokens (AppColors, AppTextStyles)
│   ├── data/                         # Data layer (DTO models, remote datasources, repository impls)
│   ├── domain/                       # Pure business domain (Entities, Contracts, Use Cases)
│   │   ├── entities/                 # Immutable domain entities
│   │   ├── repositories/             # Abstract repository contracts
│   │   └── usecases/                 # Single-responsibility use cases
│   └── presentation/                 # Presentation layer (GetX controllers, views, custom widgets)
│       ├── controllers/              # ScheduleController with mutex-guarded mutations
│       └── views/widgets/            # Reusable UI components & bottom sheets
├── test/                             # Flutter test suite (23 unit & widget tests)
└── README.md
```

---

## 🚀 The 4 Core Subscription Modification Flows

Every subscription mutation is supported by comprehensive UI/UX feedback, validation guards, and backend transaction atomicity.

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                       SUBSCRIPTION MUTATIONS                                    │
├────────────────────┬────────────────────┬─────────────────────────┬─────────────────────────────┤
│      1. SKIP       │      2. SWAP       │         3. MOVE         │        4. RESCHEDULE        │
├────────────────────┼────────────────────┼─────────────────────────┼─────────────────────────────┤
│ Removes selected   │ Pairwise exchange  │ Relocates selected      │ Shifts an entire delivery   │
│ meal items from a  │ of meals across    │ items into another      │ order to a new target date  │
│ scheduled order.   │ different dates.   │ order or date.          │ and open delivery slot.     │
└────────────────────┴────────────────────┴─────────────────────────┴─────────────────────────────┘
```

### 1. Skip Flow (`batchSkipSelected`)
- **Multi-Item Selection**: Users can select one or multiple meal items across any order on the active date using intuitive selection checkmarks.
- **Floating Action Bar**: Displays selected item count with instant options to **Skip**, **Swap**, or **Move**.
- **Ghost Order Pruning**: When all meals within a delivery slot are skipped, the backend automatically deletes the empty `MealOrder` row inside an atomic transaction.
- **Chronological Re-indexing**: Remaining orders for the day are re-indexed (`Order 1`, `Order 2`, etc.) chronologically according to their delivery window start time.
- **Cut-Off Guard**: Items belonging to orders that have passed their kitchen cut-off deadline are disabled and cannot be selected or skipped.

### 2. Swap Flow (`openBatchSwapSheet`)
- **Guided Multi-Step Flow**:
  1. For each selected source item, the user chooses a target delivery date.
  2. The UI renders the target date’s available orders with delivery time windows and cutoff notices.
  3. The user picks the target meal item to exchange.
  4. If multiple items are selected, the modal transitions smoothly step-by-step (`Step 1 of N`).
  5. A final **Review Screen** provides a side-by-side preview of all paired swaps before confirmation.
- **Cut-Off Intelligence**:
  - Meals whose kitchen cut-off time has passed display a `Cut-off Passed` warning badge in place of the `Swap` button and are dimmed to prevent invalid selections.
  - If all orders on a selected target date have passed their cut-off, a persistent warning banner alerts the user to pick a future date.
- **Atomic Two-Way Exchange**: Backend swaps item `orderId` foreign keys inside a database `$transaction`, guaranteeing both meals transfer together or neither does.

### 3. Move Flow (`openBatchMoveSheet`)
- **Multi-Day Relocation**: Allows moving selected meals into another existing order on a future date.
- **Dynamic Order Tabs (No Ghost Orders)**: The modal queries the target date’s real schedule and displays only actual, existing orders (`Order 1`, `Order 2`, etc.). Artificial placeholders or ghost orders are never shown.
- **Order Details Preview**: Selecting a target order tab reveals:
  - Delivery time window (e.g., `12:30 pm - 1:30 pm`)
  - Kitchen cut-off deadline
  - Existing meals currently in that slot (with thumbnail, name, and calories)
- **Automatic Target Provisioning**: If a slot on the target day does not yet have an active order, the backend automatically provisions the `MealOrder` with the vendor’s configured delivery window and moves the items.
- **Empty Order Deletion**: If all meals are moved out of a source order, the source order is removed and remaining orders on both source and target dates are re-indexed.

### 4. Reschedule Order Flow (`openRescheduleSheet`)
- **Cross-Date Order Relocation**: Shifts an entire delivery slot (and all its items) to a selected target date within the active subscription schedule.
- **Slot Availability Engine**: Selecting a target date queries `/api/subscription/slots/availability` in real-time.
- **Collision & Occupancy Detection**:
  - Slots already occupied by existing orders on the target date are labeled with an `Occupied` badge and disabled.
  - The order’s current delivery slot on the current day is badged as `Current Slot` and disabled to prevent redundant self-rescheduling.
  - Slots whose cutoff deadlines have passed are marked unavailable with clear explanatory text.
- **Safe Auto-Assignment**: Evaluates open slots and can automatically suggest the next available window on the chosen date.
- **Calendar Synchronization**: Upon successful reschedule, the date selector carousel automatically navigates to the target date so the user immediately sees their relocated order.

---

## 🔒 Reusable Blocking Progress Indicator & UX Reliability

To provide an uninterrupted, glitch-free experience, all asynchronous mutations are coordinated through a centralized concurrency manager.

```dart
await runWithBlockingLoading(() async {
  // Execute API mutation (Skip, Swap, Move, Reschedule, Reset, etc.)
}, message: 'Updating subscription schedule...');
```

### Key Engineering Features:
1. **Mutex Lock / Double-Click Prevention**: If a mutation is already in-flight (`isMutating.value == true`), any secondary taps (double clicks, rapid button smashing) are safely discarded.
2. **Glassmorphic Full-Screen Overlay (`AppLoadingOverlay`)**: Renders a sleek, blurred backdrop with a branded spinner and dynamic status message. Touch events across the entire screen and any open modal bottom sheets are intercepted and blocked.
3. **Minimum Perceptual Duration Threshold (450ms)**: Ultra-fast local API responses can resolve in `< 30ms`, causing an unpleasant UI flash/jitter. `runWithBlockingLoading` measures elapsed time with a `Stopwatch` and holds the overlay for a minimum of 450ms to ensure smooth visual transitions.
4. **User-Friendly Error Sanitization**: Internal database or ORM exceptions (such as constraint violations, Prisma errors, or UUIDs) are caught and translated into human-readable messages before reaching the user.

---

## 👻 Ghost Order Elimination & Chronological Normalization

In subscription systems with dynamic slots, "ghost orders" (empty order containers with 0 items, or hardcoded tabs showing non-existent orders) cause customer confusion and data corruption. Subscart eliminates ghost orders at both the database and UI layers:

| Layer | Prevention Mechanism |
| :--- | :--- |
| **Database (Prisma)** | When items are skipped or moved, the backend checks `mealItem.count({ where: { orderId } })`. If remaining items equal 0, `tx.mealOrder.delete()` removes the empty order record. |
| **Chronological Re-Indexing** | After deletions or movements, `_normalizeScheduleOrders` sorts all remaining orders for that date by their delivery window start time and renumbers them sequentially (`1..N`). |
| **Frontend Bottom Sheets** | `MoveBottomSheet` and `SwapBottomSheet` derive their tabs directly from `schedule.orders`. Empty or non-existent slots are never rendered as active order tabs. |
| **Target Auto-Creation** | If moving meals into an unpopulated slot, the backend provisions the `MealOrder` dynamically from the vendor's `DeliverySlotConfig`, ensuring database integrity. |

---

## 🌐 Vendor Operational Timezone Architecture

Food preparation and delivery cut-offs must be governed by the **vendor’s dispatch kitchen**, not the customer’s device clock. A customer in California modifying a lunch delivery for an office in New York or Mumbai must be evaluated against the kitchen's local operational deadline.

```
┌─────────────────────────────────────────────────────────────┐
│                 DEVICE CLOCK (Any Local Time)               │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTP Request
                               ▼
┌─────────────────────────────────────────────────────────────┐
│              BACKEND TIMEZONE ENGINE (Node.js)              │
│  - Converts UTC system clock to vendor.timezone             │
│  - Evaluates "today", "past", and "future" calendar days    │
│  - Compares current kitchen time against cutoff deadlines   │
└──────────────────────────────┬──────────────────────────────┘
                               │ Filtered & Enriched JSON
                               ▼
┌─────────────────────────────────────────────────────────────┐
│             POSTGRESQL DATABASE (Dynamic Slots)             │
│  - DeliverySlotConfig table stores display & cutoff times   │
│  - Normalized UTC midnight dates for consistent indexing    │
└─────────────────────────────────────────────────────────────┘
```

### Highlights:
1. **Dynamic Database Slots (`DeliverySlotConfig`)**: Slot names, delivery windows, cutoff times, and notice templates are stored in PostgreSQL—not hardcoded in application logic:
   - **Breakfast Window**: `8:00 am - 9:00 am` (Cut-off: 7:00 AM)
   - **Lunch Window**: `12:30 pm - 1:30 pm` (Cut-off: 11:00 AM)
   - **Evening Window**: `4:00 pm - 5:00 pm` (Cut-off: 3:00 PM)
   - **Dinner Window**: `7:30 pm - 8:30 pm` (Cut-off: 6:00 PM)
2. **Server-Side Cut-off Enforcement**: `_assertOrderEditable` halts any attempt to skip, swap, move, or toggle an order whose cut-off deadline has elapsed with an informative `400 Bad Request`.
3. **Frontend Visual Feedback**: Past-cutoff orders display a lock icon, show a `"Cut-off passed • Order in preparation"` notice, disable toggle switches, and hide selection checkmarks.

---

## 🛠️ Evaluator Utilities: 1-Click Database Reset

To allow evaluators and testers to test edge cases freely without needing manual database cleanup:

- **UI Reset Tool**: Located in the top app bar (3-dot overflow menu). Tapping **Reset Database** presents a confirmation dialog, invokes `/api/subscription/reset`, restores all meal plans to their original seed state, and refreshes the UI.
- **REST Endpoint**: `POST /api/subscription/reset` executes an idempotent seed with `{ forceClean: true }` and returns fresh subscription data.

---

## ⚡ Backend Setup & Run Instructions

> [!NOTE]
> **Environment Variables**: The `backend/.env` file is intentionally committed so evaluators can run the backend immediately without configuring secrets.

### 1. Prerequisites
- **Node.js** `>= 18` (v20+ recommended)
- **PostgreSQL** running locally on port `5432` (or adjust `DATABASE_URL` in `backend/.env`)

### 2. Setup Database & Start Server
```bash
# 1. Navigate to backend directory
cd backend

# 2. Install dependencies
npm install

# 3. Create database in PostgreSQL (if not already created)
createdb subscart

# 4. Push Prisma schema to PostgreSQL
npx prisma db push

# 5. Seed initial menu plans, delivery schedules, and slot configs
node prisma/seed.js

# 6. Start development server
npm run dev
```

The server will be available at `http://localhost:3000`.

### 3. Run Backend Test Suite
```bash
npm test
```
Executes **16 automated tests** using Node.js's native test runner (`node --test`), verifying:
- Timezone conversions and midnight boundary handling
- Cut-off deadline comparisons
- Dynamic delivery slot availability and occupied slot detection
- Atomic cross-date order rescheduling and collision prevention
- Deletion of empty orders upon skip/move operations
- Chronological order re-indexing (`1..N`)

---

## 📱 Flutter Application Setup

### 1. Prerequisites
- **Flutter SDK** `^3.24.0` (Dart `^3.9.0`)
- Running backend server (`http://localhost:3000`)

### 2. Run App
```bash
# 1. Install Flutter dependencies
flutter pub get

# 2. Run static analysis (verifies 0 lint errors)
flutter analyze

# 3. Run test suite (verifies 23 unit & widget tests)
flutter test

# 4. Launch application (macOS, iOS Simulator, Android, or Chrome)
flutter run
```

### 3. Smart Host Resolution
`lib/core/constants/api_constants.dart` automatically resolves the backend base URL:
- **Android Emulator**: `http://10.0.2.2:3000/api`
- **iOS Simulator / macOS / Web**: `http://localhost:3000/api`
- **Production Override**: Set `productionBaseUrl` to your deployed cloud URL (e.g., Railway, Render, AWS).

---

## 🧪 Automated Test Summary

| Test Suite | Framework | Total Tests | Status | Scope |
| :--- | :--- | :--- | :--- | :--- |
| **Backend** | Native Node.js Runner (`node --test`) | **16 Tests** | ✅ Passing | Timezone engine, Prisma transactions, slot availability, self-collision guard, empty order cleanup. |
| **Frontend** | Flutter Test Framework (`flutter test`) | **23 Tests** | ✅ Passing | Clean Architecture use cases, GetX controller state, multi-selection, blocking loaders, bottom sheets, past-cutoff states. |
| **Analysis** | `flutter analyze` | **0 Issues** | ✅ Clean | Sound null safety, strict type checking, zero linter warnings. |

---

## 🌐 API Reference

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/health` | Server health and database connection status |
| `GET` | `/api/subscription` | Fetch complete subscription, vendor config & daily schedules |
| `GET` | `/api/subscription/slots/availability` | Dynamic slot availability and collision check for target date |
| `POST` | `/api/subscription/reschedule` | Reschedule an entire order to a different date & slot |
| `POST` | `/api/subscription/items/move` | Move selected meal items to another order / day |
| `POST` | `/api/subscription/items/swap` | Atomic two-way meal item swap across dates or orders |
| `POST` | `/api/subscription/items/skip` | Skip meal item(s) and auto-delete order if empty |
| `POST` | `/api/subscription/slot/toggle` | Toggle active delivery state for an order slot |
| `POST` | `/api/subscription/pause` | Pause or resume subscription delivery cycle |
| `POST` | `/api/subscription/reset` | Restore database to default demo seed data |

---

## 📄 License
This project is open-source and available under the [MIT License](LICENSE).
