# Prompt for the backend session (atomshop): customer app v2, round 4 (corrected)

Paste everything below the line into a Claude session opened in `C:\xampp\htdocs\atomshop`.

---

Continue the customer app v2 server work in this project (Atomshop, Laravel 11). The Flutter app (`C:\MyProject\atomshop-new-app`) has its screens built against the API contract below. Build the endpoints that don't exist yet and keep the website's behaviour unchanged.

**Already pushed to `main` (not necessarily deployed):** `POST api/app/orders`, `POST api/app/ask-atom` (session / text / actions / related), notification `screen` + `order_id`, `account/my-orders` scoped to the token user (another uuid → **404**, keep it), active-brand filtering (`Product::fromActiveBrand`).
**Already fixed in the account API** (`docs/trd/2026-10-28-account-api-security.md`): no code in responses, codes expire (10 min) with a per-user try limit, reset needs a verified code or the account's own token, `delete`/`change/password`/`profile*` act only on the token's own account, `custom-order-calculator/store` refuses another account's uuid and has no `123456` password, the WhatsApp token comes from `WHATSAPP_TOKEN` in `.env`, `my-instalments`/`payment-history` return empty lists, correct receipt URLs and match `Advance`. Don't redo any of these.

Read first: `CLAUDE.md`, `.claude/RULES.md`, `.claude/ARCHITECTURE.md` (§9 rules), `.claude/MEMORY.md`, and the TRDs `docs/trd/2026-10-28-customer-app-v2-api.md`, `2026-10-28-app-product-order.md`, `2026-10-28-app-orders-and-notifications.md`, `2026-10-28-app-ask-atom.md`, `2026-10-28-account-api-security.md`.

## Working rules

- Write a TRD in `docs/trd/` before the code (one TRD for this round, sections per area).
- Fat controllers; a service only when 2+ callers share logic (then reuse it from the web side too). Every response goes through `sendResponse` / `sendError` / `sendException` with **real HTTP codes** in the new endpoints: 200 OK, 401 no/invalid token, 403 not allowed, 404 not found or not yours, 422 validation or a customer-fixable refusal (first error as `message`, field errors in `data`), 429 limits (with `data.retry_after` seconds), 500 logged with a generic message. Never echo `$e->getMessage()`.
- New endpoints live under `api/app/...` in `App\Http\Controllers\Api\App\*` and extend `Api\BaseController`. Signed-in endpoints use `auth:sanctum` and **identify the user only from the token** (never a uuid/user_id in the body). Customers only (`role === 'customer'`, `status === 'active'`), else 403.
- Money maths stays identical to the website (`InstallmentPlanService`, `Web\CustomOfferController` constants). Any change to it needs a before/after example in the commit.
- Customer creation goes through `CustomerLookupService`. Names use the `person_name` rule. Email/WhatsApp go out from queued jobs.
- **Migrations are needed in this round** (see below). They may only add nullable columns or new tables to this app's own tables: never `atompay_*`, never `migrate:fresh`.
- Write feature **and** unit tests, but do **not** run phpunit until the owner says so. `php -l`, Pint (`./vendor/bin/pint <changed files>`), `php artisan route:list --path=api/app` and `curl` on `http://localhost/atomshop/api/...` are fine.
- Don't touch AMOS, `atompay_*` schema, or the intentional typos (`Varification`, `receipet`, `provice`). Keep the old `account/*`, `my-*`, `cart/*`, `leads/create` responses working for the old store app (its source: `git show 32243b8:<path>` in the Flutter repo; it reads `message.user.uuid` from `send/code`, and `cnic_no`/`father_name` from `my-orders`).
- Update ARCHITECTURE.md (new controllers/services), MEMORY.md (decisions), TASKS.md, CLAUDE.md (routes/schema), and `.env.example` for any new variable.
- "Push" = commit on `main`, `git pull --ff-only` first, stage files by name. Don't push until the owner says so.

## Data facts to design around (checked 2026-10-28 on the local DB)

1. **Old product orders have unlinked mirrors.** Only 3 `custom_orders` rows have `source_order_id`; there are 88 `orders` and 1,176 custom orders without a link, many of them mirrors of storefront orders. "Product orders + custom orders with no `source_order_id`" would list old orders twice. Add a one-off, idempotent backfill (command or migration) that links each unlinked mirror to its `Order` (same `user_id`, same `total_deal_price` and `advance_price`, product title = the cart product's title, `created_at` within a few minutes, unique match only) and report how many stayed unmatched. List rule after the backfill: an `Order`, plus custom orders that are not a mirror.
2. **The cash price is not stored.** `ProductOrderService::finalize()` copies the total-with-markup into `custom_order_products.price`, and the order's markup rate isn't kept. Add nullable `custom_orders.cash_price`, set it in `ProductOrderService` (the catalogue/storage price used to price the order) and for seller-created custom orders from the product price; older orders return `cash_price: null`.
3. **Installment schedules are on the mirror.** All 922 `order_instalments` rows are `order_type = 'Custom'`; none are `Normal`. AtomPay orders also keep their schedule on the mirror and their status on the `Order`.
4. **146 phone numbers belong to more than one customer account** (415 duplicates were deliberately not merged). Sign-in by phone, sign-in by code and forgot password must pick one account deterministically: an exact email match wins; for a phone, the active, verified customer with the most recent order, else the newest active one. Document the rule in the TRD and test it.
5. **`leads` has no `user_id`, `offer_price` or `note` columns.** Add them (nullable) for section E.
6. **Lead statuses have spelling variants.** Stored: `New Lead`, `NewLead`, `Contacted`, `Follow-up`, `No Response`, `NoResponse`, `Won`, `Lost`, `custom ordered`. Labels: New Lead/NewLead → **New**; Contacted/Follow-up/No Response/NoResponse → **Contacted**; Won/custom ordered → **Ordered**; Lost → **Closed**; anything else → **New**.
7. **The website's contact form only saves a `Contact` row**, with no job and no staff alert. The app does exactly the same.
8. **Customers' CNIC photos have no private storage yet.** The website has no customer CNIC upload; seller uploads go to `public/images/customers/`. Add a private disk (`storage/app/private/customers`, not linked, not under `public/`) for app uploads; admins/sellers read them through an authenticated controller later (RULES §1.5).
9. **`users.last_login_at` and `last_login_from` exist.**
10. **The product page route is `website.product.detail` (`/{slug}`).**

## Shared shapes

```
User      {uuid, name, phone, email|null (null when it's the "@atomshop.pk" placeholder), joined_at "Y-m-d",
           picture_url|null, city {id,title}|null, area {id,title}|null, address|null, verified bool,
           customer_id|null (customers.identifier), father_name|null, cnic_masked|null ("35202-•••••••-1"),
           alternate_phone|null, work_address|null, cnic_front_uploaded bool, cnic_back_uploaded bool}
Money     integers in rupees (never formatted strings)
Dates     "Y-m-d" (dates) or ISO 8601 (timestamps)
Status    order status exactly as stored ("Pending","Varification","Processing","Delivered","Instalments","Completed","Cancelled")
          plus status_label for display ("Verification", "Installments", …)
```

## A. Auth (new endpoints for the app; the old `account/*` stay as fixed)

Use `BrandAppOtpService`-style codes (6 digits, 10 min, 5 tries, 3 sends / 10 min) for all codes, sent by **WhatsApp template to the phone and email if real**. The code is **never** in a response. Reuse the storefront's register and forgot-password rules (`Web\AuthController@register_perform`, `Web\PasswordController`) via a shared service rather than copying them. New app tokens are named `app-v2`; decide in the TRD whether they expire (Sanctum `expiration` is null today) and ask the owner if unsure.

| Endpoint | Request | Success `data` | Notes |
|---|---|---|---|
| POST `api/app/auth/register` | `name`, `phone` (required), `email` (optional), `password` (min 8), `password_confirmation`, `fcm_token?` | `{user_uuid, sent_to: ["whatsapp","email"], phone_masked: "0300 ••• 4567"}` | Same duplicate rule as the website (CustomerLookupService → 422 "This phone is already registered…"), same per-IP cap, user `status=pending`. |
| POST `api/app/auth/register/verify` | `user_uuid`, `code` | `{token, user: User}` | Activates (status active, `email_verified_at`), sends the welcome message (queued), **signs in**, attaches `fcm_token` if sent at register. |
| POST `api/app/auth/register/resend` | `user_uuid` | `{sent_to, phone_masked}` | Pending accounts only; send limits (429). Closes TASKS.md "a phone sign-up who loses the code gets no new one". |
| POST `api/app/auth/login` | `login` (phone or email, any phone format), `password`, `fcm_token?` | `{token, user: User}` | Duplicate-phone rule (data fact 4). Customers only (others → 403 "This app is for customers…"). Blocked/support → 403 with the website's messages. Unverified → 403 with `data {needs_verification: true, user_uuid, sent_to, phone_masked}` and a fresh code sent. **No `hack@123`.** Sets `last_login_at`, `last_login_from='App'`. |
| POST `api/app/auth/login/code` | `login` | `{challenge_id, sent_to, phone_masked\|null}` | Same answer whether or not the account exists; only active customers get a code. |
| POST `api/app/auth/login/code/verify` | `challenge_id`, `code`, `fcm_token?` | `{token, user: User}` | |
| POST `api/app/auth/password/forgot` | `login`, `channel` (`whatsapp`\|`email`, default whatsapp) | `{reset_id, sent_to, phone_masked\|null}` | Same answer whether or not the account exists (`reset_id` random either way). |
| POST `api/app/auth/password/verify` | `reset_id`, `code` | `{reset_token}` | Single use, 15 min. Wrong → 422; too many → 429. |
| POST `api/app/auth/password/reset` | `reset_token`, `password` (min 8), `password_confirmation` | `{token, user: User}` | Deletes all the user's tokens, then issues a new app token. |
| POST `api/app/auth/logout` (sanctum) | `fcm_token?` | `null` | Deletes the current token, unlinks the FCM token. |

## B. Me (sanctum)

| Endpoint | Request | Success `data` |
|---|---|---|
| GET `api/app/me` | | `User` |
| GET `api/app/me/summary` | | `{stats {orders, active_plans, paid, unpaid}, next_due {amount, date\|null, label, order_uuid, product}\|null, verification {verified, identity: "atompay"\|"atomshop"\|null, address_visit_at\|null, cnic_masked\|null}, atompay {state: none\|incomplete\|pending\|approved\|rejected, conditional, limit\|null, available\|null, max_monthly\|null, months\|null, url}, unread_notifications}`. `atompay` from `AtompayProfileService::summary()` (+ `available` = limit − `AtompayReviewService::exposure()`); totals from the same schedule rows as `api/app/installments`. |
| POST `api/app/me` | `name`, `email?` (unique, real), `city_id`, `area_id`, `address`, `father_name?`, `cnic?` (13 digits), `alternate_phone?`, `work_address?` | `User`. Phone changes are not allowed here. Same fields and rules as the storefront v2 account profile. |
| POST `api/app/me/location` | `city_id`, `area_id` | `User` (keeps the address) |
| POST `api/app/me/photo` | `photo` (image, 4 MB) | `User` |
| POST `api/app/me/cnic` | `side` (`front`\|`back`), `photo` (image, 6 MB) | `User`. Stored on the private disk (data fact 8); never returned as a URL. |
| POST `api/app/me/password` | `current_password`, `password` (min 8), `password_confirmation` | `null` (other tokens deleted, this one kept) |
| POST `api/app/me/delete` | `password` | `null`. Like `account/delete`: removes the user and customer rows, keeps orders, revokes all tokens. Store requirement. |

## C. Orders and installments (sanctum, token user only)

After the backfill (data fact 1), a customer's orders are their `orders` rows (schedule on the linked mirror) plus their custom orders that aren't mirrors. Don't list a mirror twice. AtomPay orders take their status from the `Order`.

```
OrderCard {uuid, kind: "product"|"custom", type: "atomshop"|"atompay", status, status_label,
           product {title, picture_url|null, storage|null, colour|null},
           months, advance, monthly|null, total, cash_price|null, paid, outstanding, created_at,
           next_due {amount, date|null, label}|null}
```
`paid` = advance (if paid) + paid installments; `outstanding` = total − paid. Work these out from the schedule rows (the same rows the seller and admin pages use), not with new maths. `monthly` = the schedule's regular installment (null for cash). `cash_price` from data fact 2.

| Endpoint | Success `data` |
|---|---|
| GET `api/app/orders?status=active\|completed\|all&page=` | `{orders: [OrderCard], next_page: int\|null}` (20 per page, newest first; active = not Completed/Cancelled) |
| GET `api/app/orders/{uuid}` | `OrderCard + {order_id (the number shown to customers), delivery {city, area, address}, seller {name, business_name, phone}\|null, timeline [{status, label, done, at\|null}] (Pending → Verification → Processing → Delivered → Installments → Completed; at from order_change_histories filtered by order_type), schedule [Installment], atompay_url\|null}`. 404 if not the caller's (product-order uuid or custom-order uuid). |
| GET `api/app/installments?tab=active\|pending\|completed` | `{summary {outstanding, paid, active_plans, next_due {amount, date\|null, order_uuid, product}\|null}, plans [OrderCard + {paid_months, seller {name, business_name, phone, area}\|null, schedule [Installment]}]}`. pending = Pending/Varification/Processing (no schedule yet, `schedule: []`); active = Delivered/Instalments with outstanding > 0; completed = Completed. Default tab active. Empty → 200 with empty arrays. `summary` covers all tabs. |
| GET `api/app/payments?order_uuid=&page=` | `{summary {paid, advance, monthly, outstanding}, by_method [{method, amount, percent}], orders [{uuid, label: "#48213 Galaxy A56"}], payments: [Payment], next_page}` |
| GET `api/app/payments/{id}` | `Receipt`. 404 if not the caller's. |
| GET `api/app/payments/{id}/pdf` | The receipt as a PDF (dompdf; base it on the seller receipt view `dashboards.sellers.instalment.invoice-web`), `Content-Disposition: attachment`; sanctum. |

```
Installment {id|null, label (stored `month`: "Advance","1st Month"… as stored), amount, paid_amount, due_date|null, status ("Paid"|"Unpaid"|"Overdue"), paid_at|null, method|null, receipt_url|null}
Payment     {id, order_uuid, order_id, product, label, amount, paid_at, method|null, receipt_url|null}
Receipt     Payment + {receipt_no, customer, storage|null, due_date|null, received_by|null ("Ali Electronics, Johar Town"), pdf_url}
```
`receipt_url` = `asset(receipet)` when set, else null. Overdue = unpaid with a due date before today (Asia/Karachi). `order_instalments.month` is text: show it as stored.

## D. Custom order (replaces `custom-order-calculator/store` for the app)

One shared service with `Web\CustomOfferController` (constants `MARKUP_RATE`, `SOURCING_FEE`, `MIN_ADVANCE`, the verified-supplier half fee) so web and app can't drift; the web controller must call it too, with identical output (before/after example in the TRD).

| Endpoint | Request | Success `data` |
|---|---|---|
| POST `api/app/custom-orders/quote` | `price`, `advance`, `months`, `reference_code?` | `{price, advance, min_advance, financed, markup, sourcing_fee, sourcing_fee_percent, total, monthly, months, reference: {valid, message}\|null}`. 422 when advance < 20% or > price, or months not in `InstallmentPlanService::tenures()`. |
| GET `api/app/custom-orders/reference-code?code=` | | `{valid, message}` (no business name for unverified suppliers; empty code → 422) |
| POST `api/app/custom-orders` (guest allowed; token optional like `api/app/orders`) | `product_title`, `product_link?` (url), `category?`, `notes?` (max 500), `picture?` (image, 4 MB), `price`, `advance`, `months`, `reference_code?`, `full_name`, `phone`, `email?`, `city_id`, `area_id`, `address` (multipart with a picture) | `{order_uuid, order_id, product, price, advance, sourcing_fee, monthly, total, months, area}`. The server recomputes every figure; `portal = App`; `cash_price` = price; link/notes/category go in `custom_order_products.custom_fields`; sellers notified as on the web; a guest gets a random password. Never AtomPay. |
| GET `api/app/custom-orders` (sanctum) | | `{orders: [{uuid, order_id, product, picture_url\|null, price, monthly, months, status, status_label, created_at}]}`: the caller's custom orders that aren't mirrors. |

## E. Make an offer

Keep `POST api/leads/create` working for the old app and extend it (migration from data fact 5): validate `city_id` (exists) and `area_id` (exists, optional); accept `offer_price` (integer, optional) and `note` (max 500); set `user_id` when a customer token is sent; 422 with field errors instead of 200 **only when the old app's request would still pass** (check its body in `git show 32243b8` first); no exception text. Answer `data {lead_uuid}`.

`GET api/app/offers` (sanctum): the caller's leads (by `user_id`, or by their phone, format-insensitive like `CustomerLookupService`, for leads sent before they signed up): `{offers: [{uuid, product, area, status (stored), status_label (data fact 6), note (one customer-facing line per label, e.g. New: "Waiting for a seller in your area to pick it up."), created_at}]}`.

## F. Ask Atom actions

`POST api/app/ask-atom` is live. Add to each item in `actions`: `type` (`product`|`category`|`brand`|`custom_order`|`offer`|`whatsapp`|`url`) and `id` (product, category or brand id, else null). Product links are `/{slug}`, so look the slug up (published, active-brand products only); a slug that isn't found stays `type: url, id: null`. Do it in `Api\AskAtomController::split()` or right after it; don't change the website's HTML.

## G. Content pages

`GET api/app/pages/{slug}` for `about`, `why`, `faqs`, `privacy`, `terms`, `refund`, `app-privacy`. The website's privacy page also holds the terms: serve those sections as `terms` and the privacy ones as `privacy`, while the website page keeps both. **`app-privacy` exists only as a v1 view** (`website/v1/pages/app-privacy-policy`); include it in the single source too. Move the text into one source (`config/content/*.php` or a `PageContent` class) used by the Blade views and this endpoint; the website's HTML output must stay identical (compare rendered HTML before and after in a test, like `WebsiteMetaParityTest`).

Success `data`: `{slug, title, updated_at, intro|null, sections: [{heading, paragraphs: [string], bullets: [string]}], faq_groups: [{title, items: [{q, a}]}] (faqs only), url}`. Plain text only. Platform wording ("sellers on Atomshop offer…"), British spelling but "installment(s)".

## G2. Notifications

Add `order_uuid` (the uuid `api/app/orders/{uuid}` accepts: the `Order`'s for a mirror, else the custom order's) and `payment_id` (for `instalment_paid`) to each customer notification's `data` in `CustomerNotificationService`, and return them top-level in `Api\NotificationController::format()` next to `screen`/`order_id`. Keep `order_id` for the old app. Older notifications: resolve `order_uuid` from `order_id` when listing, if cheap (one query per page).

## H. Contact form

`POST api/app/contact`: same fields and rules as `Web\PageController@contact_perform` (`name` person_name, `phone`, `subject`, `message`), saves a `Contact` row, nothing else (data fact 7). Rate limit 5/hour per IP. `data null`.

## I. Catalogue and config

- `GET api/products?q=`: add `cash_price`, `monthly_from`, `atompay` the same way as the category/brand lists (`HomePageController::withPlans`). Active-brand filtering is already in place.
- `GET api/products/{id}`: add `slug` and `url` (`route('website.product.detail', $slug)`).
- `api/app/config`: add `pages` (slug → website url) and `apps.atomseller {android, ios}` from new env keys `ATOMSELLER_APP_ANDROID` / `ATOMSELLER_APP_IOS` (add to `config/website.php` like `atombrand`, and to `.env.example`). The website shows no support hours, so don't invent them.
- `hack@123` in `Api\AccountController@login`: still waiting on the owner; don't touch it.

## J. Reliability (from the app audit)

- **Idempotent orders.** The app sends `request_id` (32 hex characters, the same for every retry of one order form) with `POST api/app/orders` and `POST api/app/custom-orders`. Store it (nullable unique column on `orders` / `custom_orders`, or a short-lived cache key per user/phone) and, when the same `request_id` arrives again, return the first order's answer instead of creating a second order. This covers double taps, timeouts and retries after a lost connection.
- **Maintenance mode.** Add to `api/app/config`: `maintenance {enabled: bool, message: string|null, until: ISO 8601|null}` from `.env` (`APP_MAINTENANCE`, `APP_MAINTENANCE_MESSAGE`, `APP_MAINTENANCE_UNTIL`; add to `.env.example`). `api/app/config` itself must keep answering during maintenance; while it is on, the `api/app/*` write endpoints answer 503 with the same message (the app screen is UX only).
- **Rate limits.** Keep 429 + `data.retry_after` on every limited endpoint (the app shows the message and never retries a 429 by itself).

## Tests (write, don't run)

Feature tests per area: register → verify signs in and never returns the code; login refuses non-customers and unverified accounts (with a new code sent); duplicate-phone rule; forgot/verify/reset with tries and expiry; `me` only for the token user; orders list/detail never show another customer's order (404) and never show a mirror twice; installments tabs and empty → 200; receipt_url; custom-order quote = web maths (before/after) and the web page still gives the same figures; minimum advance; store recomputes; leads validation without breaking the old app's body; offer status labels for every stored variant; ask-atom action types; pages text matches the website views. Unit tests for the pure parts (labels, masks, quote maths, backfill matcher).

When done, report: endpoints added (method, path, auth), migrations, files changed, the backfill's matched/unmatched counts, what was verified (php -l, Pint, route:list, curl on localhost), and what was not run.
