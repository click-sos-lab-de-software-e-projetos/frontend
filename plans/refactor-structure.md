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
> Notes: decided root occurrence types (already in `lib/`) and **adopt Retrofit**
> (deps kept; the Retrofit `@RestApi` client from the deleted copy is in git history
> and should back the `Http*` repositories in Step 4). Smoke test mocks the Geolocator
> channel. ⚠️ Gate not run (Flutter not installed on the executing machine) — run it
> before merging; `GoogleMap` platform view may need a fake in tests.
- [ ] Decide occurrence types (root: `Agressão, Discriminação, Assédio, Outro`
      vs. copy: `Assalto, Furto, Local mal iluminado, Assédio, Outro`) — see open questions.
- [ ] Delete `alerta_seguro/`.
- [ ] Remove `retrofit`, `retrofit_generator`, `build_runner` from `pubspec.yaml` (or adopt Retrofit — open question).
- [ ] Replace `test/widget_test.dart` with a smoke test that pumps `AlertaApp` and finds the 4 nav labels.
- [ ] ✅ `flutter pub get && flutter analyze && flutter test`

### Step 1 — Platform config (P2, P13)
- [ ] Apply `android_snippets/AndroidManifest_trecho.xml` to `android/app/src/main/AndroidManifest.xml`;
      read the Maps key from `local.properties` / `manifestPlaceholders` (never commit it).
- [ ] Add `NSLocationWhenInUseUsageDescription` to `ios/Runner/Info.plist`; Maps key in `AppDelegate.swift`.
- [ ] Delete `android_snippets/`.
- [ ] (Optional) rename package `com.example.alerta_seguro` → e.g. `br.edu.<faculdade>.alertaseguro`.
- [ ] ✅ App runs on an Android emulator, map loads, location permission prompt appears.

### Step 2 — Theme and shared widgets (P10, P12)
- [ ] Move colors to `app/theme.dart` (`AppColors`) and the `ThemeData` out of `main.dart`.
- [ ] Convert `sectionLabel/box/field/header/outlineButton` into `StatelessWidget`s in `shared/widgets/`.
- [ ] Make the login password field use `AppTextField(obscure: true)`.
- [ ] Replace deprecated APIs (`withValues(alpha:)`, `activeThumbColor`, `initialValue`).
- [ ] ✅ Widget tests for each shared widget; screens look identical.

### Step 3 — Models and config (P7, P9)
- [ ] Create `data/models/` with immutable models + `fromJson/toJson` + `copyWith`.
- [ ] `core/config/env.dart` with `String.fromEnvironment('API_BASE_URL')` and `bool.fromEnvironment('USE_FAKE_API', defaultValue: true)`.
- [ ] `core/network/api_client.dart`: `LogInterceptor` only when `kDebugMode`, never log bodies.
- [ ] ✅ Unit tests for model (de)serialization.

### Step 4 — Repositories (P8)
- [ ] Abstract `AuthRepository`, `OccurrenceRepository`, `AlertRepository` + `Http*` and `Fake*` implementations.
- [ ] Move the random heat-map generator into `FakeOccurrenceRepository`.
- [ ] `FakeAuthRepository` accepts any non-empty email/password; `HttpAuthRepository` **throws** on failure.
- [ ] Delete `api.dart`.
- [ ] ✅ Unit tests for repositories (Http ones with a mocked Dio adapter).

### Step 5 — Services
- [ ] `LocationService` and `WhatsAppService` classes (injectable, mockable) replacing top-level functions.
- [ ] ✅ Unit tests: phone normalization (`(11) 99122-3847` → `5511991223847`, numbers already starting with `55`), maps link.

### Step 6 — Split state into controllers (P5, P6)
- [ ] Add `provider` dependency; build a `MultiProvider` in `main.dart`.
- [ ] Split `AppState` into `AuthController`, `ProfileController`, `ContactsController`,
      `SosSettingsController`, `OccurrencesController`.
- [ ] Remove all hardcoded personal data from production code (move to fakes/seed).
- [ ] Screens use `context.watch/read` instead of manual `addListener`; dispose all `TextEditingController`s.
- [ ] Delete `state.dart`.
- [ ] ✅ Controller unit tests; no `AppState.I` or global `api` left (`grep` check).

### Step 7 — Move screens into features + fix bugs (P8, P11)
- [ ] Move each screen into `features/<name>/`; delete `lib/screens/`, `ui.dart`, `services.dart`.
- [ ] Occurrence form: `Form` + validators (address/location, type, date required), send ISO-8601 `DateTime`.
- [ ] Show errors to the user (`SnackBar`) instead of swallowing them; login shows "credenciais inválidas".
- [ ] Guard empty names in avatar initials.
- [ ] ✅ Widget tests per screen using Fake repositories (login success/failure, add contact, SOS with no active contacts shows message, occurrence validation).

### Step 8 — Quality gates
- [ ] Stricter `analysis_options.yaml` (`prefer_const_constructors`, `always_declare_return_types`, `avoid_print`, `require_trailing_commas`, ...).
- [ ] GitHub Actions workflow: `flutter analyze` + `flutter test` on every PR.
- [ ] Update README "Estrutura do projeto" section to the final layout.

## 4. Open questions (decide before Step 0)

1. **Occurrence types** — which list is correct? (root vs. `alerta_seguro/` copy)
2. **Retrofit or plain Dio?** Plan assumes plain Dio (less codegen, simpler for the team).
3. **State management** — `provider` (assumed) vs. `riverpod`/`bloc`. Check what the course expects.
4. **Backend** — is there a real backend repo/URL yet? Contract in README is still a draft.
5. **Login** — should contacts really be hidden while logged out, given SOS already uses them?

## 5. Out of scope
- New features or visual redesign.
- Real auth/session persistence (tokens, secure storage) — separate story once the backend exists.
- Navigation library (`go_router`) — revisit if screens grow.
