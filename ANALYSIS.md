# OdakPlan - Production App Analysis

> Analyzed: all files under `lib/`, platform configs (`android/`, `ios/`), `pubspec.yaml`, `analysis_options.yaml`, `test/`.

---

## 1. Architecture Overview

### State Management: Riverpod (v2.6.1) — mixed styles

| Pattern | Where Used | Files |
|---|---|---|
| `StateProvider` | selected plan id/name/minutes | `lib/app/state/selection_state.dart` |
| `StateNotifierProvider` | daily target, history, reminders, today plans, focus timer | `lib/app/state/settings_state.dart`, `lib/app/state/history_state.dart`, `lib/app/state/reminder_state.dart`, `lib/features/today/state/today_plan_notifier.dart`, `lib/features/focus/state/focus_timer_controller.dart` |
| `NotifierProvider` (newer API) | streak | `lib/app/state/streak_state.dart` |
| `Provider` (read-only) | badges, today minutes, router | `lib/app/state/badges_state.dart`, `lib/app/state/history_state.dart`, `lib/app/router.dart` |

**Verdict:** Three different Riverpod provider patterns co-exist. Not wrong per se, but it means contributors must understand all three. No `AsyncNotifierProvider` is used even though several notifiers do async I/O in `build()`.

### Storage: Hive (v2.2.3)

| Box name | Opened in | Type | Purpose |
|---|---|---|---|
| `plans` | `main.dart` | `Box<ActivityPlan>` (typed, adapter-based) | Legacy(?) typed box — not directly read by current `TodayPlanNotifier` |
| `history` | `main.dart` | `Box<int>` | Daily minutes (`yyyy-MM-dd` → int) |
| `settings` | `main.dart` | `Box<int>` | `dailyTarget`, reminder prefs |
| `op_settings` | `main.dart` | `Box<dynamic>` | Theme mode, reminder settings |
| `today_plans_box` | `TodayPlanNotifier._ensureBox()` | `Box<dynamic>` | Actual plan list (stored as `List<Map>`) |
| `stats_box` | `StatsStore._ensureBox()` | `Box<dynamic>` | Total minutes, streak, badges |

**Verdict:** Six Hive boxes with no migration strategy, no schema version, and no encryption. The `plans` typed box opened in `main.dart` appears unused by the current plan notifier (which uses `today_plans_box` with manual `Map` serialization instead).

### Routing: go_router (v14.6.2)

Flat four-tab `StatefulShellRoute.indexedStack`:

```
/today     → TodayPage
/focus     → FocusPage
/progress  → ProgressPage
/settings  → SettingsPage
```

`MainShell` in `lib/app/router.dart` hosts a `NavigationBar`. No deep-linking, no nested routes, no route guards.

### Notification Layer

`lib/app/notifications/notification_service.dart` — singleton service wrapping `flutter_local_notifications`. Three notification channels: daily reminder, focus ongoing (sticky), and session-complete (scheduled). Also declares `flutter_foreground_task` in Android manifest but **never imports it in Dart code**.

---

## 2. Top 10 Issues Hurting Maintainability / Performance

### M1. THREE duplicate `todayPlanProvider` definitions (CRITICAL)

Three separate files each export a symbol named `todayPlanProvider`:

| File | Model class | Persistence |
|---|---|---|
| `lib/features/today/state/today_plan_notifier.dart` | `ActivityPlan` | Hive `today_plans_box` |
| `lib/features/today/state/today_plan_state.dart` | `TodayPlanItem` | **None** (hardcoded list) |
| `lib/app/state/today_plan_notifier.dart` | `TodayPlan` | Hive `today_plans_box` |

`today_page.dart` imports the feature-local one. The other two are dead code but will cause ambiguous-import errors if anything accidentally pulls them in. This is the single biggest maintenance risk.

**Files:** `lib/features/today/state/today_plan_notifier.dart`, `lib/features/today/state/today_plan_state.dart`, `lib/app/state/today_plan_notifier.dart`

---

### M2. Double initialization in `main.dart`

```dart
await NotificationService.instance.init();          // line 14
await NotificationService.instance.requestPermissions(); // line 15
// … 10 lines later …
await NotificationService.instance.init();          // line 27
await NotificationService.instance.requestPermissions(); // line 30
```

`init()` is idempotent (early return if `_initialized`), but `requestPermissions()` is **not**. The user sees the permission dialog twice on first launch on some OEMs.

**File:** `lib/main.dart` lines 14-15 and 27-30

---

### M3. Hardcoded daily target `120` in FocusPage

```dart
const dailyTarget = 120;  // focus_page.dart line 151
```

The user sets their target via `dailyTargetProvider` (which defaults to 60), but the focus page ignores it and uses `120`. Streak logic, session-complete sheet, and "goal reached" indicator are all wrong for users who set anything other than 120.

**File:** `lib/features/focus/focus_page.dart` lines 151-152

---

### M4. `(ctx as Element).markNeedsBuild()` anti-pattern

The plan editor bottom sheet mutates a local `int tempMin` and forces a rebuild by casting `BuildContext` to `Element`:

```dart
(ctx as Element).markNeedsBuild();  // lines 361, 367, 381
```

This is undocumented framework behavior that can break across Flutter versions. A `StatefulBuilder` (like the one used in `_editTarget`) or a `StatefulWidget` sheet would be safe.

**File:** `lib/features/today/today_page.dart` lines 361, 367, 381

---

### M5. Blanket `catch (_) {}` throughout the codebase

At least 12 instances of silent error swallowing:

- `lib/app/state/history_state.dart` — lines 50, 75, 89, 102, 109, 122
- `lib/features/focus/focus_page.dart` — lines 126, 133, 159, 167
- `lib/features/settings/settings_page.dart` — line 70
- `lib/app/notifications/notification_service.dart` — line 127

With no crash reporting service, these silent catches make debugging production issues essentially impossible.

---

### M6. Timer notification updated every second

`FocusTimerController.start()` fires `_updateOngoingNotification()` **every tick** (1 s). On Android, this calls `FlutterLocalNotificationsPlugin.show()` each second. Although `onlyAlertOnce: true` suppresses sound, it still invokes platform channels 60×/min, allocates notification objects, and burns battery.

**File:** `lib/features/focus/state/focus_timer_controller.dart` lines 145-168

**Fix:** Update the notification every 15-30 seconds, or only when the displayed minute value changes.

---

### M7. Unused `Ref` parameter in `DailyMinutesNotifier`

```dart
class DailyMinutesNotifier extends StateNotifier<Map<String, int>> {
  DailyMinutesNotifier(this._ref) : super(const {}) { ... }
  final Ref _ref;   // never read
```

**File:** `lib/app/state/history_state.dart` line 21, 26

---

### M8. `withOpacity()` called on `Color` — deprecated in Flutter 3.x

Found in at least 7 files. `Color.withOpacity()` creates a new `Color` every call and is deprecated. Should migrate to `Color.withValues(alpha: …)`.

**Files:** `lib/app/theme.dart`, `lib/features/today/widgets/plan_item_card.dart`, `lib/features/settings/settings_page.dart`, `lib/features/focus/widgets/session_complete_sheet.dart`, `lib/features/progress/progress_page.dart`, `lib/shared/ui/section_card.dart`

---

### M9. `ActivityPlanAdapter` registered but `plans` box never read

`main.dart` registers `ActivityPlanAdapter` and opens a typed `Box<ActivityPlan>('plans')`. But the actual plan notifier (`TodayPlanNotifier`) uses `Hive.openBox('today_plans_box')` with manual `Map` serialization. The typed box is dead weight.

**Files:** `lib/main.dart` lines 18-21, `lib/features/today/models/activity_plan_adapter.dart`

---

### M10. Single smoke test with wrong box names

The test file opens boxes like `stats`, `streak`, `badges`, `app`, `prefs`, `preferences`, `app_settings`, `notification_settings` — **none of which match** the actual box names used by the app (`history`, `settings`, `op_settings`, `today_plans_box`, `stats_box`).

**File:** `test/widget_test.dart` lines 26-38

---

## 3. Top 10 UX Friction Points (Inferred from Code)

### U1. Tapping a plan card auto-navigates to Focus — no "select only" option

In `today_page.dart` lines 82-98, `onTap` on a plan card does three things atomically: sets selected plan, shows a snackbar, **and calls `context.go('/focus')`**. There is no way for the user to select a plan without being yanked to another tab. This is especially jarring for users who want to browse plans or select one before they're ready to focus.

---

### U2. Edit/Delete is only via undiscoverable long-press

The only way to edit or delete a plan is `onLongPress` (line 100). The hint is a small subtitle: "uzun bas: düzenle/sil". There is no swipe-to-dismiss, no visible edit icon, no overflow menu. Many users will never discover this.

**File:** `lib/features/today/today_page.dart` line 60-61, 100

---

### U3. No undo after destructive actions

Deleting a plan is permanent after the confirmation dialog. There is no undo snackbar with a timer, no recycle bin, no way to recover. Same for "Ayarları sıfırla" (reset settings).

---

### U4. Snackbar spam on every action

Snackbars fire for: plan selected, plan added, plan updated, plan deleted, target changed, early completion, and setting changes. Multiple snackbars queue and overlay each other. On a fast workflow (select plan → immediately start focus), the user sees 2-3 stacked snackbars.

**Files:** `lib/features/today/today_page.dart` (lines 91-96, 199, 226, 301), `lib/features/focus/focus_page.dart` (line 140), `lib/features/settings/settings_page.dart` (lines 93, 112, 115, 201, 294, 354)

---

### U5. Break duration is not user-configurable

`FocusTimerController` hardcodes `breakMinutes: 5`. There is no setting to change break length. Power users who prefer longer breaks (10-15 min) or shorter ones (2-3 min) are stuck.

**File:** `lib/features/focus/state/focus_timer_controller.dart` line 60

---

### U6. Progress page locked to 7-day view

`ProgressPage` always shows exactly the last 7 days. There's no week/month toggle, no calendar picker, no scroll-back. Users who've used the app for weeks can't see their older data.

**File:** `lib/features/progress/progress_page.dart` line 20

---

### U7. Slider min/max inconsistency for plan minutes

In the plan editor sheet, the `Slider` has `min: 10` but the minus `IconButton` allows decrementing down to `5`. Users can create a 5-minute plan via the button but the slider won't reflect it (clamped to 10).

**File:** `lib/features/today/today_page.dart` lines 359-361 vs 374

---

### U8. "Premium" / "PRO" labels with no actual IAP

The settings page shows "PRO" badge (line 479) and "Premium" pill (line 196), plus footer text "Premium görünüm". There is no in-app purchase, no paywall, no subscription. These labels create false expectations or suggest the app is incomplete.

**File:** `lib/features/settings/settings_page.dart` lines 196, 294, 302-304, 479

---

### U9. No onboarding or first-run guidance

The app seeds 4 default plans on first launch (Ders Çalışma, Dil Çalışma, Kitap Okuma, Hobi/Proje) but there's no welcome screen, no explanation of what the Focus timer does, no prompt to set a daily target. New users land on a pre-populated plan list with no context.

---

### U10. All text is hardcoded Turkish — no localization

Every UI string is embedded directly in widget `build()` methods in Turkish. There is no `AppLocalizations`, no `.arb` files, no `intl` usage for strings (only for date formatting). The app cannot be used by non-Turkish speakers without a code change.

---

## 4. Store Readiness Risks

### Play Store (Android)

| Risk | Severity | Detail |
|---|---|---|
| **`SCHEDULE_EXACT_ALARM` requires justification** | HIGH | Android 14+ requires declaring why exact alarms are needed. Google may reject or remove the app without a valid use-case declaration in the Play Console. **File:** `android/app/src/main/AndroidManifest.xml` line 7 |
| **R8/ProGuard disabled** | MEDIUM | `isMinifyEnabled = false` in release build. APK size is unnecessarily large. **File:** `android/app/build.gradle.kts` lines 63-64 |
| **`android:label="odakplan"` (lowercase)** | LOW | Display name should be "OdakPlan" for branding. **File:** `android/app/src/main/AndroidManifest.xml` line 17 |
| **`foregroundServiceType="dataSync"` declared but unused** | MEDIUM | Google audits foreground service types. Declaring `dataSync` when it's not used may trigger rejection. **File:** `android/app/src/main/AndroidManifest.xml` lines 59-63 |
| **No privacy policy** | BLOCKING | Play Store requires a privacy policy URL for apps that access notifications and use local storage. Not found anywhere in the project. |

### App Store (iOS)

| Risk | Severity | Detail |
|---|---|---|
| **`UIDeviceFamily` = `[1]` (iPhone only)** | MEDIUM | iPad is excluded. Apple guidelines say universal apps are preferred. If reviewers test on iPad, it will run in compatibility mode. **File:** `ios/Runner/Info.plist` lines 36-38 |
| **No `NSUserNotificationUsageDescription`** | HIGH | The app requests notification permissions but Info.plist has no usage description string. App Store review may flag this. **File:** `ios/Runner/Info.plist` |
| **No App Transport Security exception or `NSAppTransportSecurity`** | LOW | Not an issue now (no network calls), but will become one if analytics/backend is added. |
| **`CFBundleName = "odakplan"` (lowercase)** | LOW | Should match branded name "OdakPlan". **File:** `ios/Runner/Info.plist` line 15 |
| **No privacy policy** | BLOCKING | Same as Android — required by Apple. |

### Cross-Platform

| Risk | Severity | Detail |
|---|---|---|
| **No crash reporting** | HIGH | No Crashlytics, Sentry, or equivalent. Production issues are invisible. |
| **pubspec description is "A new Flutter project."** | LOW | Not visible to end users but signals unfinished setup. **File:** `pubspec.yaml` line 2 |
| **`flutter_foreground_task` imported but not used in Dart** | MEDIUM | Dependency adds ~200KB to binary and a service declaration but nothing in `lib/` imports it. Dead dependency. |
| **No `dart:io` platform check before `Platform.isIOS`** | LOW | `notification_service.dart` uses `Platform.isIOS` which crashes on web. App doesn't target web currently but the web scaffold exists. **File:** `lib/app/notifications/notification_service.dart` line 93 |

---

## 5. Prioritized Incremental Action Plan

### P0 — Must Fix Before Store Submission

| # | Action | Effort | Files |
|---|---|---|---|
| P0-1 | **Remove duplicate `todayPlanProvider` files.** Delete `lib/features/today/state/today_plan_state.dart` and `lib/app/state/today_plan_notifier.dart`. Keep only `lib/features/today/state/today_plan_notifier.dart`. | 15 min | 3 files |
| P0-2 | **Remove double init/requestPermissions in `main.dart`.** Delete lines 27-30 (the second `init()` + `requestPermissions()` calls). | 2 min | `lib/main.dart` |
| P0-3 | **Fix hardcoded `dailyTarget = 120` in FocusPage.** Replace with `ref.read(dailyTargetProvider)`. | 5 min | `lib/features/focus/focus_page.dart` |
| P0-4 | **Add privacy policy URL.** Create a hosted privacy policy page and reference it in Play Console and App Store Connect metadata. | 1 hr | External |
| P0-5 | **Remove unused `flutter_foreground_task` dependency and manifest service declaration** if you aren't using foreground tasks. Or implement it properly if you are. | 10 min | `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml` |
| P0-6 | **Fix `SCHEDULE_EXACT_ALARM` justification.** Either add a declaration in the Play Console explaining timer notifications, or downgrade to `inexactAllowWhileIdle` where possible. | 15 min | `lib/app/notifications/notification_service.dart`, Play Console |
| P0-7 | **Add iOS notification usage description** to `Info.plist` (`NSUserNotificationUsageDescription` or equivalent `UNAuthorizationOptions` description). | 5 min | `ios/Runner/Info.plist` |

### P1 — Should Fix for Quality & Stability

| # | Action | Effort | Files |
|---|---|---|---|
| P1-1 | **Replace `(ctx as Element).markNeedsBuild()`** with `StatefulBuilder` in the plan editor sheet. | 20 min | `lib/features/today/today_page.dart` |
| P1-2 | **Throttle ongoing notification updates** to once per 15-30 seconds (or only when displayed minute changes). | 15 min | `lib/features/focus/state/focus_timer_controller.dart` |
| P1-3 | **Replace silent `catch (_) {}`** with a lightweight logger (e.g., `dart:developer` `log()`) at minimum. Add crash reporting (Sentry/Crashlytics) as a follow-up. | 30 min | Multiple files (see M5 list) |
| P1-4 | **Remove unused `plans` typed box and `ActivityPlanAdapter`** (or migrate to use it properly). Currently dead code that runs at startup. | 15 min | `lib/main.dart`, `lib/features/today/models/activity_plan_adapter.dart` |
| P1-5 | **Fix slider min/max inconsistency.** Either set slider `min: 5` or clamp the button decrement to `10`. | 5 min | `lib/features/today/today_page.dart` |
| P1-6 | **Enable R8/ProGuard** for release builds. Set `isMinifyEnabled = true` and `isShrinkResources = true`, add ProGuard rules for Hive and notifications. | 30 min | `android/app/build.gradle.kts` |
| P1-7 | **Fix test file box names** to match actual app box names, and add at least basic unit tests for `DailyMinutesNotifier`, `StreakNotifier`, and `FocusTimerController`. | 1 hr | `test/widget_test.dart`, new test files |
| P1-8 | **Remove unused `_ref` in `DailyMinutesNotifier`** or use `Ref` for cross-provider coordination. | 2 min | `lib/app/state/history_state.dart` |

### P2 — Nice to Have / UX Improvements

| # | Action | Effort | Files |
|---|---|---|---|
| P2-1 | **Decouple plan selection from navigation.** Add a separate "Start Focus" button on the Today page; make card tap only select. Navigation to Focus should be explicit. | 30 min | `lib/features/today/today_page.dart` |
| P2-2 | **Add swipe-to-edit or visible edit icons** on plan cards so edit/delete isn't long-press-only. | 30 min | `lib/features/today/widgets/plan_item_card.dart`, `lib/features/today/today_page.dart` |
| P2-3 | **Reduce snackbar noise.** Remove the "Seçildi" snackbar, keep only snackbars for destructive/important actions. Add undo support for plan deletion. | 20 min | `lib/features/today/today_page.dart` |
| P2-4 | **Make break duration configurable.** Add a "Mola süresi" setting in Settings or in the Focus page mode switcher. | 45 min | `lib/features/focus/state/focus_timer_controller.dart`, `lib/features/settings/settings_page.dart` |
| P2-5 | **Extend Progress page** with a week/month toggle or scrollable date range. | 2 hr | `lib/features/progress/progress_page.dart` |
| P2-6 | **Remove or implement "Premium"/"PRO" labels.** Either remove the misleading labels or add an actual IAP gate. | 15 min | `lib/features/settings/settings_page.dart` |
| P2-7 | **Add localization infrastructure** (`flutter_localizations` + `.arb` files). Start with Turkish + English. | 2 hr | Multiple files |
| P2-8 | **Migrate `withOpacity()` calls** to `Color.withValues(alpha: …)` to clear deprecation warnings. | 20 min | 6+ files (see M8 list) |
| P2-9 | **Add a simple onboarding flow** — a 2-3 step intro explaining daily target, plans, and the focus timer. | 2 hr | New files |
| P2-10 | **Unify Riverpod provider style.** Migrate all `StateNotifier`-based providers to the newer `Notifier`/`AsyncNotifier` API for consistency. | 2 hr | All state files |

---

## Summary

OdakPlan is a focused, well-scoped productivity app with clean Material 3 UI and a sensible feature set. The core loop (plan → focus → track) works. The main risks are **duplicate provider definitions** that will cause import conflicts, **silent error handling** that hides production bugs, and **missing store compliance items** (privacy policy, notification descriptions, unused permissions). The P0 items are all small, safe fixes that should be done before any store submission.
