# Prompt for the backend session (atomshop): customer app v2, round 4

Paste everything below the line into a Claude session opened in `C:\xampp\htdocs\atomshop`.

---

Continue the customer app v2 server work in this project (Atomshop, Laravel 11). The Flutter app (`C:\MyProject\atomshop-new-app`) has its screens built against the API contract below. Several endpoints don't exist yet, and several of the existing `account/*`, `my-*` and custom-order APIs are unsafe or unusable. Build the contract, fix the security issues listed, and keep the website's behaviour unchanged.

**Already live (commit 9ae541d7, deployed):** `POST api/app/orders`, `POST api/app/ask-atom` (session / text / actions / related), notification `screen` + `order_id`, `account/my-orders` scoped to the token user, active-brand filtering. Don't redo those; build everything else below.

Read first: `CLAUDE.md`, `.claude/RULES.md`, `.claude/ARCHITECTURE.md` (§9 rules), `.claude/MEMORY.md`, and the two existing TRDs `docs/trd/2026-10-28-customer-app-v2-api.md` and `docs/trd/2026-10-28-app-product-order.md` (POST `api/app/orders` and `Website\ProductOrderService` exist, uncommitted unless already pushed).

## Working rules (same as before)

- Write a TRD in `docs/trd/` before the code (one TRD for this round is fine, sections per area).
- Fat controllers; a service only when 2+ callers share logic (then reuse it from the web side too). Every response through `sendResponse` / `sendError` / `sendException` with **real HTTP codes** in the new endpoints: 200 OK, 401 no/invalid token, 403 not allowed, 404 not found, 422 validation or a customer-fixable refusal (first error as `message`, field errors in `data`), 429 limits (with `data.retry_after` seconds), 500 logged, generic message. Never echo `$e->getMessage()`.
- New endpoints live under `api/app/...` in a new controller namespace `App\Http\Controllers\Api\App\*` (or `Api\App*Controller`), extend `Api\BaseController`. Signed-in endpoints use `auth:sanctum` and **identify the user only from the token** (never a uuid/user_id in the body), customers only (`role === 'customer'`, `status === 'active'`), else 403.
- Money maths stays identical to the website (`InstallmentPlanService`, `Web\CustomOfferController` constants). Any change to it needs a before/after example in the commit.
- Customer creation goes through `CustomerLookupService`. Names use the `person_name` rule. Email/WhatsApp from queued jobs.
- Write feature tests but do **not** run phpunit until the owner says so. `php -l`, Pint (`./vendor/bin/pint <changed files>`), `php artisan route:list --path=api/app` are fine.
- Don't touch AMOS, `atompay_*` schema, or the intentional typos (`Varification`, `receipet`, `provice`). Keep the old `account/*`, `my-*`, `cart/*` endpoints working for the old app, except where the security fixes below say otherwise.
- Update ARCHITECTURE.md (new controllers/services), MEMORY.md (decisions), TASKS.md, and `.env.example` for any new variable.
- "Push" = commit on `main`, `git pull --ff-only` first, stage files by name. Don't push until the owner says so.

## Shared shapes

```
User      {uuid, name, phone, email|null (null when it's the "@atomshop.pk" placeholder), joined_at "Y-m-d",
           picture_url|null, city {id,title}|null, area {id,title}|null, address|null, verified bool,
           customer_id|null (customers.identifier), father_name|null, cnic_masked|null ("35202-•••••••-1"),
           alternate_phone|null, work_address|null, cnic_front_uploaded bool, cnic_back_uploaded bool}
Money     integers in rupees (never formatted strings)
Dates     "Y-m-d" (dates) or ISO 8601 (timestamps)
Status    order status exactly as stored ("Pending","Varification","Processing","Delivered","Instalments","Completed","Cancelled")
          plus status_label for display ("Verification" etc.)
```

## A. Auth (replaces `account/login|create|send/code|verify|reset/password` for the app)

Use `BrandAppOtpService`-style codes (6 digits, 10 min, 5 tries, 3 sends / 10 min) for all codes, sent by **WhatsApp template to the phone and email if real**. The code is **never** in a response. Reuse the storefront's register and forgot-password rules (`Web\AuthController@register_perform`, `Web\PasswordController`) via a shared service rather than copying them.

| Endpoint | Request | Success `data` | Notes |
|---|---|---|---|
| POST `api/app/auth/register` | `name`, `phone` (required), `email` (optional), `password` (min 8), `password_confirmation`, `fcm_token?` | `{user_uuid, sent_to: ["whatsapp","email"], phone_masked: "0300 ••• 4567"}` | Same duplicate rule as the website (CustomerLookupService → 422 "This phone is already registered…"), same per-IP cap, user `status=pending`. |
| POST `api/app/auth/register/verify` | `user_uuid`, `code` | `{token, user: User}` | Activates the account (status active, `email_verified_at`), sends the welcome message, **signs in** (Sanctum token `app-v2`), attaches `fcm_token` if sent at register. |
| POST `api/app/auth/register/resend` | `user_uuid` | `{sent_to, phone_masked}` | Only for pending accounts; send limits apply (429). Fixes TASKS.md "a phone sign-up who loses the code gets no new one". |
| POST `api/app/auth/login` | `login` (phone or email, any phone format), `password`, `fcm_token?` | `{token, user: User}` | Customers only (others → 403 "This app is for customers…"). Blocked/support status → 403 with the website's messages. Unverified account → 403 with `data {needs_verification: true, user_uuid, sent_to, phone_masked}` and a fresh code sent. **No `hack@123` bypass.** Sets `last_login_at`, `last_login_from='App'`. |
| POST `api/app/auth/login/code` | `login` (phone or email) | `{challenge_id, sent_to, phone_masked\|null}` | "Get a code on WhatsApp" sign-in. Same answer whether or not the account exists; only active customers get a code. |
| POST `api/app/auth/login/code/verify` | `challenge_id`, `code`, `fcm_token?` | `{token, user: User}` | Signs in without a password. Tries/expiry as above. |
| POST `api/app/auth/password/forgot` | `login`, `channel` (`whatsapp`\|`email`, default whatsapp) | `{reset_id, sent_to, phone_masked\|null}` | Same answer whether or not the account exists (`reset_id` is an opaque random id either way; `phone_masked` null when unknown). Only active customers actually get a code. |
| POST `api/app/auth/password/verify` | `reset_id`, `code` | `{reset_token}` | Single-use token valid 15 min. Wrong code → 422; too many tries → 429. |
| POST `api/app/auth/password/reset` | `reset_token`, `password` (min 8), `password_confirmation` | `{token, user: User}` | Sets the password, deletes all the user's Sanctum tokens (as the website does), then issues a new app token so the app is signed in. |
| POST `api/app/auth/logout` (sanctum) | `fcm_token?` | `null` | Deletes the current token, unlinks the FCM token. |

## B. Me (sanctum)

| Endpoint | Request | Success `data` |
|---|---|---|
| GET `api/app/me` | | `User` |
| GET `api/app/me/summary` | | `{stats {orders, active_plans, paid, unpaid}, next_due {amount, date\|null, label, order_uuid, product}\|null, verification {verified, identity: "atompay"\|"atomshop"\|null, address_visit_at\|null, cnic_masked\|null}, atompay {state: none\|incomplete\|pending\|approved\|rejected, conditional, limit\|null, available\|null, max_monthly\|null, months\|null, url}, unread_notifications}` — `atompay` from `AtompayProfileService::summary()` (+ `available` = limit − `AtompayReviewService::exposure()`); totals from the same schedule rows as `api/app/installments`. |
| POST `api/app/me` | `name`, `email?` (unique, real), `city_id`, `area_id`, `address`, `father_name?`, `cnic?` (13 digits), `alternate_phone?`, `work_address?` | `User` (phone changes are not allowed here; they need a code later). Same fields and rules as the storefront v2 account profile. |
| POST `api/app/me/location` | `city_id`, `area_id` | `User` — the sign-up "Where should we deliver?" step; keeps the address. |
| POST `api/app/me/photo` | `photo` (image, 4 MB) | `User` |
| POST `api/app/me/cnic` | `side` (`front`\|`back`), `photo` (image, 6 MB) | `User` — stored outside `public/` like the website's verification upload; never returned as a URL. |
| POST `api/app/me/password` | `current_password`, `password` (min 8), `password_confirmation` | `null` (other tokens are deleted, this one kept) |
| POST `api/app/me/delete` | `password` | `null` — same as `account/delete` but authorised by token + password; keep orders for records as the existing delete does. Store requirement. |

## C. Orders and installments (sanctum, token user only)

A customer's "orders" are their product orders (`orders` rows, with the CustomOrder mirror linked by `source_order_id` holding the installment schedule) **plus** their custom orders (`custom_orders` rows with no `source_order_id`). Don't list a mirror twice. AtomPay orders take their status from the `Order`.

```
OrderCard {uuid, kind: "product"|"custom", type: "atomshop"|"atompay", status, status_label,
           product {title, picture_url|null, storage|null, colour|null},
           months, advance, monthly|null, total, paid, outstanding, created_at,
           next_due {amount, date|null, label}|null}
```
`paid` = advance (if paid) + paid installments; `outstanding` = total − paid. Work these out on the server from the schedule rows (the same rows the seller and admin pages use), not with new maths. `monthly` = the schedule's regular installment amount (null for cash).

| Endpoint | Success `data` |
|---|---|
| GET `api/app/orders?status=active\|completed\|all&page=` | `{orders: [OrderCard], next_page: int\|null}` (20 per page, newest first; active = not Completed/Cancelled) |
| GET `api/app/orders/{uuid}` | `OrderCard + {order_id (the number shown to customers), delivery {city, area, address}, seller {name, business_name, phone}\|null, timeline [{status, label, done: bool, at\|null}] (Pending → Verification → Processing → Delivered → Installments → Completed), schedule [Installment], atompay_url\|null}` — 404 if not the caller's (by product-order uuid or custom-order uuid). |
| GET `api/app/installments` | `{summary {outstanding, paid, active_plans, next_due {amount, date\|null, order_uuid, product}\|null}, plans [OrderCard filtered to orders with a schedule and outstanding > 0]}` — empty lists are `200` with empty arrays, never an error. |
| GET `api/app/payments?order_uuid=&page=` | `{summary {paid, advance, monthly, outstanding}, by_method [{method, amount, percent}], orders [{uuid, label: "#48213 Galaxy A56"}], payments: [Payment], next_page}` |
| GET `api/app/payments/{id}` | `Receipt` — 404 if not the caller's. |
| GET `api/app/payments/{id}/pdf` | the receipt as a PDF (dompdf, same look as the seller receipt), `Content-Disposition: attachment`; sanctum. |

```
Installment {id|null, label ("Advance","1st month"…), amount, paid_amount, due_date|null, status ("Paid"|"Unpaid"|"Overdue"), paid_at|null, method|null, receipt_url|null}
Payment     {id, order_uuid, order_id, product, label, amount, paid_at, method|null, receipt_url|null}
Receipt     Payment + {receipt_no, customer, storage|null, due_date|null, received_by|null ("Ali Electronics, Johar Town"), pdf_url}
```
The Installments screen has tabs: `GET api/app/installments?tab=active|pending|completed` where pending = ordered, not yet delivered (Pending, Varification, Processing), active = Delivered/Instalments with outstanding > 0, completed = Completed. Each plan in `plans` also carries `{paid_months, seller {name, business_name, phone, area}|null, schedule [Installment]}` so the tab shows progress and the schedule without a second call.

`receipt_url` = `asset(receipet)` when the column is set, else null (the existing API has this inverted). Overdue = unpaid with a due date before today (Asia/Karachi).

### Security fixes for the old endpoints (keep them for the old app)
- `account/my-orders`: use the token user; ignore/compare the body `uuid` (403 on mismatch). Stop returning `cnic_no`/`father_name` there unless the app needs them (it doesn't).
- `account/my-instalments`, `account/payment-history`: return an empty list as success; fix the inverted receipt; `Advnace` typo in the code (the DB value is `Advance`).
- `account/send/code` and `account/create` return the code in the response, and `account/send/code/reset/password` resets any password with only a uuid: an account takeover (send/code hands out the uuid). Stop returning the code, and require a verified code / reset token on reset (the new app passes `code` along already). `account/delete/{uuid}`, `account/change/password`, `account/profile/update` must use the token user (sanctum) and ignore body/URL uuids that differ.
- `custom-order-calculator/store`: don't let an anonymous caller order on another account via `uuid`; validate like the web form; no default password `123456`.

## D. Custom order (replaces `custom-order-calculator/store` for the app)

Use one shared service with `Web\CustomOfferController` (constants `MARKUP_RATE`, `SOURCING_FEE`, `MIN_ADVANCE`, the verified-supplier half fee) so the web and app can't drift.

| Endpoint | Request | Success `data` |
|---|---|---|
| POST `api/app/custom-orders/quote` | `price`, `advance`, `months`, `reference_code?` | `{price, advance, min_advance, financed, markup, sourcing_fee, sourcing_fee_percent, total, monthly, months, reference: {valid, message}\|null}` — 422 when advance < 20% or > price, months outside the calculator's `tenures()`. |
| GET `api/app/custom-orders/reference-code?code=` | | `{valid: bool, message}` (no business name for unverified suppliers; empty code → 422) |
| POST `api/app/custom-orders` (guest allowed, sanctum token optional like `api/app/orders`) | `product_title`, `product_link?` (url), `category?`, `notes?` (max 500), `picture?` (image, 4 MB), `price`, `advance`, `months`, `reference_code?`, `full_name`, `phone`, `email?`, `city_id`, `area_id`, `address` (multipart when a picture is sent) | `{order_uuid, order_id, product, price, advance, sourcing_fee, monthly, total, months, area}` — the server recomputes every figure (same as the quote); `portal = App`; sellers notified as on the web. |

| GET `api/app/custom-orders` (sanctum) | | `{orders: [{uuid, order_id, product, picture_url\|null, price, monthly, months, status, status_label, created_at}]}` — the caller's custom orders (`custom_orders` with no `source_order_id`). |

## E. Make an offer

Keep `POST api/leads/create` (the app uses it today) and extend it: validate `area_id` (exists, optional) and `city_id` (exists); accept `offer_price` (integer, optional) and `note` (max 500); link `user_id` when a customer token is sent; return 422 with field errors instead of 200; don't leak exception text. Answer `data {lead_uuid}`.

Add `GET api/app/offers` (sanctum): the caller's leads (by `user_id`, or by their phone for leads sent before they signed up): `{offers: [{uuid, product, area, status (stored value), status_label ("New","Contacted","Ordered","Closed"), note (one customer-facing line per status, e.g. "Waiting for a seller in your area to pick it up."), created_at}]}`.

## F. Ask Atom in the app (done; small additions)

`POST api/app/ask-atom` is live and the app uses its shape as deployed: request `question`, `history`, `suggestion_id`, `session` (the signed id from the previous answer); answer `text` (line breaks, `**bold**`), `actions [{label, url}]`, `related {title, questions}`, `session`. The app maps action links to its own screens by URL (wa.me → WhatsApp, `/custom-order…` → custom order, `/make-offer` → make an offer, `/category/{slug}` → that category) and opens the rest in the browser. Please add to each action, where known, `type` (`product`|`category`|`brand`|`custom_order`|`offer`|`whatsapp`|`url`) and `id` (product, category or brand id), so product and brand links open in the app instead of the browser.

## G. Content pages

`GET api/app/pages/{slug}` for `about`, `why`, `faqs`, `privacy`, `terms`, `refund`, `app-privacy` (the store-listed app privacy policy). The website's privacy page also holds the terms ("Acceptance of terms", Eligibility, Pricing…): serve those sections as `terms` and the privacy ones as `privacy`, while the website page keeps showing both. Move the storefront v2 text (`resources/views/website/v2/pages/*.blade.php`, FAQ array in `faqs.blade.php`) into one source (e.g. `config/content/*.php` or a `PageContent` class) used by both the Blade views and this endpoint, so the website and app never differ. Keep the website's HTML output identical.

Success `data`: `{slug, title, updated_at, intro|null, sections: [{heading, paragraphs: [string], bullets: [string]}], faq_groups: [{title, items: [{q, a}]}] (faqs only), url (the website page)}`. Plain text only (no HTML). Platform wording ("sellers on Atomshop offer…"), British spelling but "installment(s)".

## G2. Notifications

The existing `api/notifications` API is fine (token-scoped) and the app uses it. Add `order_uuid` (the product order's or custom order's uuid, whichever `api/app/orders/{uuid}` accepts) and `payment_id` (for `instalment_paid`) to each customer notification's `data` in `CustomerNotificationService`, so a tap opens that order or receipt. Keep `order_id` for the old app.

## H. Contact form

`POST api/app/contact` — same as the website's `contact-us` form (`Web\PageController@contact_perform`: same fields, rules and job): `name`, `phone`, `subject`, `message`. Rate-limit it (5/hour per IP). `data null`.

## I2. Catalogue additions

- `GET api/products?q=` (the app's product search): add `cash_price`, `monthly_from`, `atompay` the same way as the category/brand lists (`HomePageController::withPlans`) and only products of active brands (`Product::fromActiveBrand`). Today the search cards show "Price on request".
- `GET api/products/{id}`: add `slug` and `url` (the website product page, `route('website.product.detail', slug)`), so the app's share button sends a link.
- Order detail (`api/app/orders/{uuid}`, section C): include `cash_price` (the product's or storage price when ordered) for the "Cash price" row.

## I. Also

- `api/app/config`: add `pages` (slug → website url), `support_hours` if the website shows them, and `apps.atomseller {android, ios}` (the Atom Seller app's store links; the app's ecosystem page shows store buttons only for links the config sends).
- Remove the hard-coded Meta/WhatsApp access tokens in `app/Traits/WhatsAppTrait.php` (two `Bearer EAA…` strings); read them from config/.env and tell the owner to rotate them.
- `hack@123` in `Api\AccountController@login`: the new app no longer uses that endpoint; ask the owner before removing it there.

## Tests (write, don't run)

Feature tests per area: register → verify signs in and never returns the code; login refuses non-customers and unverified accounts (with a new code sent); forgot/verify/reset with tries and expiry; `me` only for the token user; orders list/detail never show another customer's order (404); installments/payments empty → 200; receipt_url correct; custom-order quote = web maths (before/after example), minimum advance, store recomputes; leads validation; ask-atom limits and HTML → actions; pages text matches the website views.

When done, report: endpoints added (method, path, auth), files changed, what was verified (php -l, Pint, route:list, curl on localhost), what was not run.
