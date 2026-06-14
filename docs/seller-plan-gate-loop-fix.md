# Seller plan-gate infinite refetch loop — issue & fix notes

## Symptom

On any seller screen whose data requires a subscription **plan the account
doesn't have** (e.g. a Marketing-only account opening **Leads**, or a screen
behind the Financial plan), the screen would sit on its loading skeleton for a
very long time (~1 minute, sometimes effectively forever) before finally
showing the "You need an active … plan" gate. The device also janked
("Skipped N frames") while it happened.

Originally misreported as a "slow loading / subscription loading" problem.

## What it was NOT

We chased several plausible-but-wrong causes first. Recording them so nobody
re-investigates them:

- **Not the network/server.** A direct `curl` of the gated endpoint
  (`POST /seller-app/login` then `GET /seller-app/leads`) returned the `403`
  with the plan message in **~0.4s**. Login on-device was also fast.
- **Not secure-storage / token reads.** On-device timing showed
  `[SESSION] read … 4–11ms`. (We still kept a small token/session in-memory
  cache as a minor improvement, but it was not the cause.)
- **Not the tab "stampede".** Lazy-loading the shell tabs helped startup a bit
  but did not fix this.
- **Not `keepAlive()`.** Adding `ref.keepAlive()` on the gate exception did
  **not** stop the loop.

## Actual root cause

Debug logging made it unambiguous — the provider was **re-running on every
rebuild, forever**:

```
[LEADS-SCREEN] build   keyHash=77155890
[LEADS-VM] RUN         keyHash=77155890     ← fetch
[NET ✗ 403] /leads                          ← gate
[LEADS-SCREEN] build   keyHash=77155890     ← rebuild
[LEADS-VM] RUN         keyHash=77155890     ← fetch AGAIN … repeats
```

The data providers are `FutureProvider.autoDispose`. When the repository
**throws** `SellerPlanUpgradeException`, the provider enters an **`AsyncError`**
state. In this app's setup, an errored autoDispose provider gets **re-executed
when the consuming screen rebuilds** — and the screen rebuilds *because* the
provider's state changes — so it becomes a self-sustaining loop that hammers
the API. `keepAlive` does not pin an errored autoDispose state, and even making
the provider non-autoDispose did not stop it.

Tell-tale comparison: the **dashboard never looped**, because it already
**catches** the plan exception and **returns it as data** (a `revenueGate`
field) instead of throwing. An `AsyncData` state is stable; an `AsyncError`
state is not.

## The fix — "gate as data"

Never let a plan gate surface as a thrown error / `AsyncError`. Instead, catch
`SellerPlanUpgradeException` in the provider and **return it as part of the
data**, so the provider settles into a stable `AsyncData` state. The screen
reads the gate off the data and renders `SellerPlanGateState`.

Two equivalent shapes are used:

### A. Gate field on the response model (list screens)

For feature responses we own, add an optional `gate` field + a `.gated()`
factory:

```dart
class SellerLeadsBundle {
  // … existing fields …
  final SellerPlanUpgradeException? gate;
  const SellerLeadsBundle({ /* … */, this.gate });

  factory SellerLeadsBundle.gated(SellerPlanUpgradeException gate) =>
      SellerLeadsBundle(/* empty values */, gate: gate);
}
```

Viewmodel:

```dart
final sellerLeadsBundleProvider = FutureProvider.autoDispose
    .family<SellerLeadsBundle, SellerLeadsQuery>((ref, query) async {
  try {
    return await ref.read(sellerLeadsRepositoryProvider).getLeadsBundle(query);
  } on SellerPlanUpgradeException catch (e) {
    ref.keepAlive();
    return SellerLeadsBundle.gated(e);
  }
});
```

Screen (`data:` branch):

```dart
data: (bundle) {
  if (bundle.gate != null) {
    return SellerPlanGateState(exception: bundle.gate!);
  }
  // … normal UI …
}
```

### B. Generic `SellerGated<T>` wrapper (reports + detail providers)

When the payload has many/nested required fields (constructing an "empty"
instance is painful), wrap it instead — `lib/features/seller/core/models/seller_gated.dart`:

```dart
class SellerGated<T> {
  final T? value;
  final SellerPlanUpgradeException? gate;
  const SellerGated.value(this.value) : gate = null;
  const SellerGated.gated(this.gate) : value = null;
  bool get isGated => gate != null;
}
```

Viewmodel returns `SellerGated<Response>`:

```dart
final sellerUpcomingDuesProvider = FutureProvider.autoDispose
    .family<SellerGated<UpcomingDuesResponse>, UpcomingDuesQuery>((ref, q) async {
  try {
    return SellerGated.value(await repo.getUpcomingDues(q));
  } on SellerPlanUpgradeException catch (e) {
    ref.keepAlive();
    return SellerGated.gated(e);
  }
});
```

Screen:

```dart
data: (g) {
  if (g.isGated) return SellerPlanGateState(exception: g.gate!);
  final data = g.value!;
  // … normal UI using `data` …
}
```

## Important supporting detail — stable family keys

A `FutureProvider.family` de-dupes by the **argument's `==` / `hashCode`**.
If a screen builds a **fresh** query object on every `build()` and the query
class lacks value equality, every rebuild creates a *new* provider → a new
fetch → loop, independent of the gate. Ensure query classes override
`==`/`hashCode` (all current ones do), and prefer a **stable** query field over
a getter that allocates each build (see `seller_leads_screen.dart`).

## Files changed (high level)

- `core/auth/seller_session_manager.dart` — in-memory session cache, bounded
  reads (minor perf; not the root fix).
- `core/network/network_manager.dart` — tighter timeouts; don't trip the
  subscription gate on the subscription endpoint itself.
- `features/seller/shell/view/seller_shell_screen.dart` — lazy tab loading.
- Gate-as-data (field) applied to: **leads, custom_orders, website_orders,
  standard_orders, customers, instalments, investments, sales_team (list),
  fee_charge**.
- `SellerGated<T>` wrapper applied to: all **13 reports** providers/screens and
  the **sales_team performance/edit** detail providers.

## Checklist for any NEW seller screen behind a plan

1. Provider `catch (SellerPlanUpgradeException e)` → `keepAlive()` →
   return gate as data (`.gated(e)` or `SellerGated.gated(e)`). **Never
   rethrow.**
2. Screen `data:` branch renders `SellerPlanGateState` from the gate.
3. The provider's `family` argument has `==`/`hashCode`; pass a stable instance.
