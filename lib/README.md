# Atomshop customer app

Design: canvas "Atomshop App Redesign". Server contract: `atomshop/docs/trd/2026-10-28-customer-app-v2-api.md`.
Customer only (sellers have their own app), guest-first, no cart, Home driven from admin (App setup).

Entry: `main.dart` → `app.dart` (`AtomApp`) → `shell/atom_shell.dart`.

## Folders

| Folder | What lives there |
|---|---|
| `design/` | `AtomColors`, `AtomSpace`, `AtomRadius`, `AtomSize`, `AtomText`, `AtomTheme`. Use tokens, never raw colours or sizes. |
| `responsive/` | Breakpoints (compact < 600, medium < 1024, expanded), `context.atomScreen`, `context.atomGutter`, `context.atomPick(...)`, `atomGridColumns`, `AtomPageWidth`, `AtomTextScaleClamp`. |
| `memory/` | Image cache budget (`AtomImageMemory`). |
| `data/` | Models and API clients: catalogue (`AtomCatalogueApi`), product page (`ProductDetail`), product orders (`AtomOrderApi`), accounts (`AtomAuthApi`), signed-in data, custom orders, offers, Ask Atom, pages (`AtomAccountApi`) over `AtomHttp`. `atom_design_content.dart`: the design's fixed slider, categories and apps (brands and products stay live). Server contract: `docs/backend-prompt-app-v2.md`. |
| `state/` | Riverpod providers: session (guest / signed in), app config, catalogue, `ref.cacheFor`. |
| `utils/` | `AtomFormat` (rupees, dates), `atom_validators.dart` (name, phone, email, login, password rules shared by every form). |
| `widgets/` | Shared widgets. Build every screen from these. |
| `core/` | Kept from the old app: `network/` (`NetworkManager`, `ApiEndpoints`), `auth/session_manager.dart`, `services/` (FCM, Facebook events). |
| `shell/` | Five-tab shell (bottom bar on phones, rail on tablets), one navigator per tab. `AtomNav`: every route (lists open inside the tab, other pages full screen). `AtomUpdateGate`: forced update below `version.min`, a one-time prompt below `version.latest` (from `api/app/config`). |
| `screens/` | One folder per screen. |

## Rules

1. **Buttons always have an icon.** `AtomButton` requires one. Choice chips and tabs are text only.
2. **Remote pictures only through `AtomNetworkImage`**: it decodes at display size.
3. **Lists are lazy**: `ListView.builder` / `SliverGrid.builder` / `AtomProductSliverGrid`, never a `Column` of all items.
4. **Screen data in `FutureProvider.autoDispose` (or `AsyncNotifierProvider.autoDispose`) with `ref.cacheFor(...)`**, not in widget state, so it is freed after the screen is left.
5. **Controllers** (`TextEditingController`, `PageController`, `AnimationController`, timers) are created in a `State` and disposed in `dispose()`. Widgets never create them in `build`.
6. **Never hard-code contact details, plan rules or money maths.** Read `appConfigProvider`; monthly prices come from the API (`monthly_from`, product `plan`).
7. **Responsive**: no fixed screen widths. Use `context.atomGutter`, `atomPick`, `atomGridColumns`, and wrap page bodies in `AtomPageWidth`.
8. **Async UI** through `AtomAsync` (skeleton, error with retry, keeps old data while refreshing).
9. **Guest vs signed in** only from `atomSessionProvider` / `atomSignedInProvider`.
10. Money with `AtomFormat.rupees`, dates with `AtomFormat.date` (d M Y).
