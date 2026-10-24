# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app (requires dart-define for Supabase credentials)
flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_PUBLISHABLE_KEY=<key> --dart-define=DASHBOARD_API_BASE_URL=<api_url>

# Analyze
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Build Android release (AAB for Play Store)
flutter build appbundle --release --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_PUBLISHABLE_KEY=<key>

# Build Windows MSIX (for Windows Store)
flutter pub run msix:create
```

All runtime config is injected via `--dart-define` — there are no `.env` files. The required defines are `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`. `DASHBOARD_API_BASE_URL` is needed for pickup-window and Uber delivery API calls. `WINDOWS_UPDATE_MANIFEST_URL` has a default pointing to the GitHub releases manifest.

## Architecture

### Startup & navigation flow

`main.dart` bootstraps Supabase, provides all BLoC cubits globally, and drives the root widget tree entirely through state listeners — there is no imperative navigation. The app shell renders different top-level screens based on a layered state cascade:

1. `WindowsUpdateCubit` — on Windows, checks a remote manifest and blocks the UI with a forced update screen if the current version is below the minimum.
2. `AuthCubit` — shows `LoginScreen` when unauthenticated; once authenticated triggers `LocationCubit.loadLocations()`.
3. `LocationCubit` — shows `LocationSelectorScreen` if no location is persisted or available; once a location is selected it triggers `OrdersCubit.loadOrders()` and `StoreAvailabilityCubit.loadForLocation()`.
4. `AuthenticatedHomeScreen` — renders when all three are satisfied; hosts a stage bar (Realtime / Orders / Products / Settings) that switches between the main feature screens.

### Layer structure

```
lib/
  config/           — Supabase config (dart-define), theme, router, screen_adapt
  infrastructure/
    models/         — Pure Dart data classes (no Flutter deps); one file per domain
    services/       — Supabase RPC wrappers, realtime subscriptions, HTTP calls
  presentation/
    bloc/           — Cubits + states (one folder per cubit, state in a `part` file)
    screens/        — Full-screen widgets
    widgets/        — Reusable and screen-scoped sub-widgets
```

Barrel files (`bloc.dart`, `screens.dart`, `widgets.dart`, `services.dart`, `models.dart`) re-export everything in their layer so intra-layer imports stay short.

### State management

All state is managed with `flutter_bloc` Cubits. Cubits are injected at the root via `MultiBlocProvider` in `main.dart` and accessed via `context.read<>()` / `context.watch<>()`/`BlocBuilder`. State objects are immutable and use `copyWith`; `Equatable` is used on states that power `BlocBuilder` to prevent unnecessary rebuilds.

### Orders domain (most complex)

`OrdersCubit` is the core cubit. Key behaviors:

- **Optimistic UI with undo**: `moveOrderForward`/`moveOrderBackward` immediately update local state, record a `_PendingOrderMove`, and schedule a 3-second timer before the Supabase write. During the grace period the UI shows an undo snackbar. `undoOrderMove` cancels the timer and restores the previous state.
- **Dual model**: `OrderRealtimeOrder` is the full raw model returned by RPCs; `OrderSummary` is the lightweight display model. Both are held in `OrdersState` (`ordersRaw` and `orders`). The selected order detail sheet uses `selectedOrderRaw` and `selectedOrderSummary`.
- **Realtime**: `OrdersRealtimeService` opens two Supabase Postgres-change channels per location — one on `mediasis.orders` (for new/updated orders) and one on `mediasis.uber_deliveries` (for courier status). New order events trigger a full RPC fetch; `ready` status transitions are applied locally without a fetch.
- **Incoming alert**: New orders while the board is loaded increment `pendingIncomingAlertCount` and trigger a looping sound via `OrderSoundService`. Tapping the full-screen overlay clears the count and stops the sound.

### Services pattern

Services are plain Dart classes injected into cubits via constructor parameters (defaulting to real implementations). All Supabase calls go through `supabase.schema('mediasis').rpc(...)` for RPCs or `.from('table')` for direct table writes. HTTP calls to `DASHBOARD_API_BASE_URL` (pickup window, Uber delivery) use the `http` package with a Bearer token from the current Supabase session.

### Responsive layout

`screen_adapt.dart` provides extension methods on `num`: `ws(context)` returns `width * (n/100)` and `hs(context)` returns `height * (n/100)`. Sizes are always clamped with `.clamp(min, max)` to handle both phone and desktop widths. `AuthenticatedHomeScreen` switches between phone and desktop layout using a `LayoutBuilder` breakpoint.

### Windows auto-update

On Windows only, `WindowsUpdateCubit.initialize()` fetches a JSON manifest from `WINDOWS_UPDATE_MANIFEST_URL`, compares `minimum_supported_version` against the running version, and if an update is required downloads the installer, verifies its SHA-256 hash, and launches it before calling `exit(0)`. Non-Windows platforms skip this entirely.

## Publishing

- **Android**: `flutter build appbundle --release`. Requires `android/key.properties` with keystore credentials. App ID is `com.mediasis.dashboardapp`. Increment version in `pubspec.yaml` before each upload.
- **Windows Store**: `flutter pub run msix:create`. MSIX config in `pubspec.yaml` under `msix_config`. Published as `mediasis.mediasisOrders`.
