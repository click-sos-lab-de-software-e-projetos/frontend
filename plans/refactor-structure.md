# Refactor plan — project structure and code quality

> Goal: reorganize the Alerta Seguro app into a predictable, testable structure
> (feature-first + layers) **without changing user-visible behavior**, fixing the
> bugs/inconsistencies found along the way.
>
> Each step must leave the app compiling with `flutter analyze` clean and
> `flutter test` green. Do one step per PR.

## 1. Current state (diagnosis)

```
lib/
├── main.dart          # MaterialApp + theme + bottom-nav Shell
├── api.dart           # Dio client, global `api`, hardcoded baseUrl
├── services.dart      # location, WhatsApp, maps link (top-level functions)
├── state.dart         # models (Contact, Occurrence) + AppState singleton + mock data
├── ui.dart            # colors + helper *functions* returning widgets
└── screens/           # 8 screens, each talks directly to `api` and `AppState.I`
```

### Problems found

| # | Area | Problem |
|---|------|---------|
| P1 | Repo | `alerta_seguro/` is a stale nested copy of the whole app (diverges in `api.dart` and occurrence types). Confusing and duplicates code. |
| P2 | Repo | `android_snippets/` was never applied: the real `AndroidManifest.xml` has **no** location/internet permissions and **no** Google Maps API key. iOS `Info.plist` has no `NSLocationWhenInUseUsageDescription`. |
| P3 | Deps | `retrofit`, `retrofit_generator`, `build_runner` are declared but unused (root `api.dart` uses plain Dio). README still said to run `build_runner`. |
| P4 | Tests | `test/widget_test.dart` is the Flutter template — references `MyApp` (doesn't exist), so `flutter test` fails. No real tests. |
| P5 | State | `AppState.I` global singleton mixes profile, auth, contacts, SOS settings and occurrences. Hardcoded personal mock data lives in production state. |
| P6 | State | Screens call `app.addListener(...)` in `initState` and never remove it → leak + `setState` after dispose risk. `TextEditingController`s are never disposed. |
| P7 | Data | Untyped `Map<String, dynamic>` everywhere; no models with `fromJson`/`toJson`; JSON parsing is inline in `MapScreen`. |
| P8 | Errors | Every API call is wrapped in `catch (_) {}`. Login **always succeeds**, even with wrong credentials. Users never see failures. Fake data is mixed with error handling. |
| P9 | Config | `baseUrl` hardcoded in `api.dart`; no way to switch dev/prod/mock. `LogInterceptor` logs request bodies (incl. password) in release. |
| P10 | UI | `ui.dart` helpers are functions, not widgets (no `const`, worse rebuilds, harder to test). Login duplicates the text-field styling. Theme lives in `main.dart`. |
| P11 | Bugs | `OccurrenceScreen._save` builds `"null null"` when date/time aren't picked; no form validation; `Contact.name.substring(0, 1)` crashes on empty name. |
| P12 | Lints | Deprecated APIs: `Color.withOpacity`, `SwitchListTile.activeColor`, `DropdownButtonFormField.value`. |
| P13 | Naming | Android package is still `com.example.alerta_seguro`. |

## 2. Target structure

Feature-first, with a thin shared core. State via **`provider` + `ChangeNotifier`**
(smallest jump from the current `ChangeNotifier` code; easy for the team to learn).

```
lib/
├── main.dart                     # bootstrap only: read config, build providers, runApp
├── app/
│   ├── app.dart                  # MaterialApp
│   ├── shell.dart                # bottom navigation
│   └── theme.dart                # AppColors + ThemeData
├── core/
│   ├── config/env.dart           # API_BASE_URL, USE_FAKE_API via --dart-define
│   ├── network/api_client.dart   # Dio factory, interceptors (logs only in debug)
│   └── services/
│       ├── location_service.dart
│       └── whatsapp_service.dart # phone normalization + wa.me + maps link
├── data/
│   ├── models/                   # Contact, Occurrence, UserProfile, SosSettings (+ fromJson/toJson)
│   └── repositories/
│       ├── auth_repository.dart          # abstract + HttpAuthRepository + FakeAuthRepository
│       ├── occurrence_repository.dart    # abstract + Http + Fake (random heat data)
│       └── alert_repository.dart         # abstract + Http + Fake
├── features/
│   ├── auth/        login_screen.dart, auth_controller.dart
│   ├── map/         map_screen.dart, map_controller.dart, widgets/heat_circles.dart
│   ├── occurrence/  occurrence_screen.dart, occurrence_form_controller.dart
│   ├── sos/         sos_screen.dart, sos_controller.dart, widgets/sos_button.dart
│   ├── settings/    settings_screen.dart (uses SosSettingsController)
│   ├── profile/     profile_screen.dart, edit_profile_screen.dart, profile_controller.dart
│   └── contacts/    add_contact_screen.dart, contacts_controller.dart
└── shared/widgets/  section_label.dart, app_card.dart, app_text_field.dart,
                     page_header.dart, outline_action_button.dart

test/
├── core/services/whatsapp_service_test.dart
├── data/models/*_test.dart
├── features/**/*_controller_test.dart
└── features/**/*_screen_test.dart   # widget tests using Fake repositories
```

Rules:
- Screens never import `dio` or call HTTP; they talk to controllers.
- Controllers depend on **abstract** repositories (injected), never on globals.
- Fake repositories replace the current "catch and use mock data" logic; they're
  selected by `USE_FAKE_API=true`, not by catching errors.

## 3. Steps

### Step 0 — Clean up the repo (P1, P3, P4) [Done] ✅
> Notes: root occurrence types kept (already in `lib/`); **plain Dio** — removed
> `retrofit`, `retrofit_generator`, `build_runner`. Smoke test mocks the Geolocator
> channel and advances past Dio's 10s timeout. `flutter test` green (needed a fix in
> `ui.dart` `box()`: transparent `Material` so `ListTile`s inside don't assert).
> `flutter analyze` reports only the 8 deprecation infos covered by Step 2 (P12).
- [x] Decide occurrence types (root: `Agressão, Discriminação, Assédio, Outro`
      vs. copy: `Assalto, Furto, Local mal iluminado, Assédio, Outro`) — see open questions.
- [x] Delete `alerta_seguro/`.
- [x] Remove `retrofit`, `retrofit_generator`, `build_runner` from `pubspec.yaml` (or adopt Retrofit — open question).
- [x] Replace `test/widget_test.dart` with a smoke test that pumps `AlertaApp` and finds the 4 nav labels.
- [x] ✅ `flutter pub get && flutter analyze && flutter test`

### Step 1 — Platform config (P2, P13) [Done] ✅
> Notes: Maps key read from `MAPS_API_KEY` in `android/local.properties` (Gradle
> `manifestPlaceholders`) and `ios/Flutter/Secrets.xcconfig` (→ `GMSApiKey` in Info.plist),
> both git-ignored. Package rename skipped (optional; needs the faculty name).
> ⚠️ Device check pending: no Android SDK/Xcode on the executing machine.
- [x] Apply `android_snippets/AndroidManifest_trecho.xml` to `android/app/src/main/AndroidManifest.xml`;
      read the Maps key from `local.properties` / `manifestPlaceholders` (never commit it).
- [x] Add `NSLocationWhenInUseUsageDescription` to `ios/Runner/Info.plist`; Maps key in `AppDelegate.swift`.
- [x] Delete `android_snippets/`.
- [ ] (Optional) rename package `com.example.alerta_seguro` → e.g. `br.edu.<faculdade>.alertaseguro`.
- [ ] ✅ App runs on an Android emulator, map loads, location permission prompt appears.

### Step 2 — Theme and shared widgets (P10, P12) [Done] ✅
> Notes: `ui.dart` removed (helpers replaced by `shared/widgets/`); `AppCard` keeps the
> transparent `Material` fix. `AlertaApp`/`Shell` moved to `app/`.
- [x] Move colors to `app/theme.dart` (`AppColors`) and the `ThemeData` out of `main.dart`.
- [x] Convert `sectionLabel/box/field/header/outlineButton` into `StatelessWidget`s in `shared/widgets/`.
- [x] Make the login password field use `AppTextField(obscure: true)`.
- [x] Replace deprecated APIs (`withValues(alpha:)`, `activeThumbColor`, `initialValue`).
- [x] ✅ Widget tests for each shared widget; screens look identical.

### Step 3 — Models and config (P7, P9) [Done] ✅
> Notes: models use plain `lat`/`lng` doubles (no Maps dependency in `data/`); added
> `OccurrenceReport` (POST /occurrences) and `SosAlert` (POST /alerts). `Env` is
> injectable (`Env(...)` / `Env.fromEnvironment()`).
- [x] Create `data/models/` with immutable models + `fromJson/toJson` + `copyWith`.
- [x] `core/config/env.dart` with `String.fromEnvironment('API_BASE_URL')` and `bool.fromEnvironment('USE_FAKE_API', defaultValue: true)`.
- [x] `core/network/api_client.dart`: `LogInterceptor` only when `kDebugMode`, never log bodies.
- [x] ✅ Unit tests for model (de)serialization.

### Step 4 — Repositories (P8) [Done] ✅
> Notes: `Repositories` bundles the three and is built from `Env` (`fake()` / `http(dio)`).
> Failures surface as `RepositoryException` / `InvalidCredentialsException` (pt-BR message).
> Until Step 6, screens reach them via a temporary global in `state.dart`. Http tests use
> `test/helpers/stub_dio_adapter.dart` (no extra dependency).
- [x] Abstract `AuthRepository`, `OccurrenceRepository`, `AlertRepository` + `Http*` and `Fake*` implementations.
- [x] Move the random heat-map generator into `FakeOccurrenceRepository`.
- [x] `FakeAuthRepository` accepts any non-empty email/password; `HttpAuthRepository` **throws** on failure.
- [x] Delete `api.dart`.
- [x] ✅ Unit tests for repositories (Http ones with a mocked Dio adapter).

### Step 5 — Services [Done] ✅
> Notes: `LocationService` (abstract) + `GeolocatorLocationService` / `FakeLocationService`,
> returning a `GeoPoint` record (no Maps type in core). `WhatsAppService` takes an injectable
> URL launcher. Normalization also handles `+`, trunk `0` and DDD 55 (RS) vs country code.
> `services.dart` deleted; temporary globals in `state.dart` until Step 6.
- [x] `LocationService` and `WhatsAppService` classes (injectable, mockable) replacing top-level functions.
- [x] ✅ Unit tests: phone normalization (`(11) 99122-3847` → `5511991223847`, numbers already starting with `55`), maps link.

### Step 6 — Split state into controllers (P5, P6) [Done] ✅
- [x] Add `provider` dependency; build a `MultiProvider` in `main.dart`.
- [x] Split `AppState` into `AuthController`, `ProfileController`, `ContactsController`,
      `SosSettingsController`, `OccurrencesController`.
- [x] Remove all hardcoded personal data from production code (move to fakes/seed).
- [x] Screens use `context.watch/read` instead of manual `addListener`; dispose all `TextEditingController`s.
- [x] Delete `state.dart`.
- [x] ✅ Controller unit tests; no `AppState.I` or global `api` left (`grep` check).

> Notes: Steps 6 and 7 were done together, with screens rewritten straight into `features/`.
> DI goes through `lib/app/dependencies.dart` (`AppDependencies.fromEnv`). The map controller
> is `features/map/occurrences_controller.dart`. `SosController` is a plain class provided via
> `Provider` because it holds no UI state. Demo data lives in `lib/data/fakes/demo_seed.dart`.

### Step 7 — Move screens into features + fix bugs (P8, P11) [Done] ✅
- [x] Move each screen into `features/<name>/`; delete `lib/screens/`, `ui.dart`, `services.dart`.
- [x] Occurrence form: `Form` + validators (address/location, type, date required), send ISO-8601 `DateTime`.
- [x] Show errors to the user (`SnackBar`) instead of swallowing them; login shows "credenciais inválidas".
- [x] Guard empty names in avatar initials.
- [x] ✅ Widget tests per screen using Fake repositories (login success/failure, add contact, SOS with no active contacts shows message, occurrence validation).

> Notes: Time is also required in the occurrence form. The date/time is sent as UTC ISO-8601.
> The forms use `SingleChildScrollView` instead of `ListView` so every field is built and
> validated, even when it is off-screen. `SosButton` has its own test for the 3 s hold.

### Step 8 — Quality gates [Done] ✅
- [x] Stricter `analysis_options.yaml` (`prefer_const_constructors`, `always_declare_return_types`, `avoid_print`, `require_trailing_commas`, ...).
- [x] GitHub Actions workflow: `flutter analyze` + `flutter test` on every PR.
- [x] Update README "Estrutura do projeto" section to the final layout.

> Notes: Besides the listed rules, the analyzer now uses `strict-casts`/`strict-raw-types`
> and `unawaited_futures`, and the formatter width is 120 (`formatter.page_width`). CI
> (`.github/workflows/ci.yml`) also checks formatting. README updated in Portuguese (structure,
> screens table, `--dart-define` backend config, provider in the stack).

## 4. Open questions (decided 2026-10-21)

1. **Occurrence types** — which list is correct? (root vs. `alerta_seguro/` copy)
   → **Root**: `Agressão, Discriminação, Assédio, Outro`.
2. **Retrofit or plain Dio?** Plan assumes plain Dio (less codegen, simpler for the team).
   → **Plain Dio.** Retrofit deps removed in Step 0.
3. **State management** — `provider` (assumed) vs. `riverpod`/`bloc`. Check what the course expects.
   → **`provider`** + `ChangeNotifier`.
4. **Backend** — is there a real backend repo/URL yet? Contract in README is still a draft.
   → **No backend yet.** `USE_FAKE_API` defaults to `true`; `Fake*` repositories are the
     default runtime path, `Http*` follow the README draft contract.
5. **Login** — should contacts really be hidden while logged out, given SOS already uses them?
   → **Yes**, keep contacts hidden while logged out (current behavior).

## 5. Out of scope
- New features or visual redesign.
- Real auth/session persistence (tokens, secure storage) — separate story once the backend exists.
- Navigation library (`go_router`) — revisit if screens grow.
