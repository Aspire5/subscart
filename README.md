# Subscart - Meal Plan & Subscription Management App

> 📺 **Video Walkthrough**: [**Watch the Full Video Walkthrough on Google Drive**](https://drive.google.com/file/d/10WIAfA099wkx-dpOfy6zU5ktrkroMs4n/view?usp=sharing)

A modern, offline-first Flutter application built with **Clean Architecture** and **GetX** for managing recurring meal subscriptions, daily order schedules, cross-date batch meal swaps, order moves, delivery rescheduling, and automated cut-off notices.

---

## 📱 Application Overview

**Subscart** empowers meal subscription subscribers to take complete control of their recurring delivery schedules. Subscribers can seamlessly customize their daily meals, pause subscriptions, swap meals across different dates with step-by-step conflict prevention, move items to other slots/days, and reschedule delivery windows.

---

## ✨ Key Features

### 1. 📅 Interactive Day Schedule Carousel
- Horizontally scrollable day picker displaying short day labels and dates.
- Instant reactive schedule switching without page reloads.
- Safe state isolation: switching dates automatically resets active item selections.

### 2. ⚡ Floating Batch Action Bar & Multi-Select
- Select one or multiple meal items across different orders on any day.
- A non-blocking, elevated floating action bar dynamically appears with action shortcuts:
  - **Batch Skip**: Skip multiple selected items in one action.
  - **Batch Swap**: Launch a guided swap wizard for all selected items.
  - **Batch Move**: Relocate selected items to a target date and order slot.
  - **Clear**: Instantly deselect all active items.
- Compact badge and responsive flex design optimized for narrow (320dp–480dp) screens.

### 3. 🔄 Multi-Item Step-by-Step Swap Wizard
- **Guided Step-by-Step Pairing**: For multi-selected meals, guides the user step-by-step (`Step X of N: Pair "[Meal Name]"`).
- **Collision & Conflict Prevention**: Target meals chosen in earlier steps are automatically disabled (`Paired`) in later steps.
- **Auto Date-Sync**: Navigating back via "Previous Item" auto-syncs the date carousel to the target date previously chosen for that item.
- **Review & Change Summary**: Displays a clean before-and-after comparison (`Source Item ⇄ Target Item`) with individual "Change" buttons before final batch execution.

### 4. 📦 Batch Move to Target Days & Slots
- Move selected meals from today's orders into any available upcoming day and specific order slot (`Order 1`, `Order 2`, or `Order 3`).
- Automatic clean empty states if an order has all its items moved or skipped.

### 5. ⏰ Delivery Rescheduling & Cut-off Notices
- Reschedule time windows (`Breakfast`, `Lunch`, `Evening`, `Dinner`).
- Dynamic cut-off notices indicating the exact deadline before which edits are permitted.

### 6. ⏸️ Subscription Pause & Delivery Slot Toggles
- Individual Cupertino toggle switches for each delivery slot.
- Master Pause/Resume switch for the entire subscription plan.

### 7. 💾 Offline-First Persistent State
- Powered by `LocalStorageService` with local storage fallback (`GetStorage` / `SharedPreferences`).
- Changes made in the app (skips, moves, swaps, toggles, reschedules) persist across app restarts.

---

## 🏗️ Architecture & Technology Stack

The codebase follows **Uncle Bob's Clean Architecture** principles with a strict separation of concerns into three layers:

```
lib/
├── core/
│   ├── network/          # Dio HTTP client & ApiResult abstractions
│   ├── storage/          # LocalStorageService for persistence
│   ├── theme/            # AppColors, AppTheme, AppTextStyles
│   └── utils/            # DateFormatter helpers
├── data/
│   ├── datasources/      # MockSeedData, SubscriptionLocalDataSource
│   ├── models/           # Data models with JSON serialization
│   └── repositories/     # SubscriptionRepositoryImpl implementation
├── domain/
│   ├── entities/         # Immutable business entities
│   ├── repositories/     # Abstract repository contracts
│   └── usecases/         # Single-responsibility use cases
└── presentation/
    ├── bindings/         # GetX Dependency Injection bindings
    ├── controllers/      # ScheduleController (Reactive Rx State)
    ├── routes/           # AppPages & AppRoutes
    └── views/            # ScheduleView and modular UI widgets
```

### Tech Stack:
- **Framework**: [Flutter](https://flutter.dev) (Dart SDK `^3.9.2`)
- **State Management & DI**: [GetX](https://pub.dev/packages/get)
- **Local Persistence**: [GetStorage](https://pub.dev/packages/get_storage)
- **HTTP Client Scaffolding**: [Dio](https://pub.dev/packages/dio)
- **Image Caching**: [cached_network_image](https://pub.dev/packages/cached_network_image)
- **Date Formatting**: [intl](https://pub.dev/packages/intl)

---

## 🤖 Use of AI Disclosure

I am willingly and proactively disclosing the use of AI in the development of this project:
- **Code Development & Logic**: Developed with the **AntiGravity model (Gemini 3.7 Flash)** for Clean Architecture modeling, GetX state management, batch usecase implementations, widget tree optimizations, and unit test suites.
- **Frontend & UI Aesthetics**: User interface layout concepts, typography, spacing tokens, and design specifications were crafted using **Google Stitch**.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `>=3.24.0` or latest stable)
- [Dart SDK](https://dart.dev/get-dart) (version `>=3.9.0`)
- Android Studio / Xcode / VS Code with Flutter extension
- An active Android/iOS emulator or connected physical device

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Aspire5/subscart.git
   cd subscart
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Static Code Analysis**:
   ```bash
   flutter analyze
   ```

4. **Run Unit & Widget Tests**:
   ```bash
   flutter test
   ```

5. **Launch the Application**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing

The test suite covers core business logic, multi-item batch operations, and controller reactive states:
- Initial subscription and schedule loading.
- Single and batch meal skipping across orders on the same day.
- Cross-date meal swapping with target slot updates.
- Single and batch moving of meals to different dates and order slots.
- Delivery slot active state toggling and cut-off notice calculations.
- Master subscription pause/resume status toggling.
- `ScheduleController` multi-selection state management and auto-clearing on date changes.

Run all tests via:
```bash
flutter test
```

---

## 📄 License
This project is open-source and available under the [MIT License](LICENSE).
