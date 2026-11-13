# Play Store listing — Atomshop

Copy for the Play Console **Store listing** page. Written against build 30
(version 2.0.0), which added offline offers, custom orders and profile
changes, and put AtomPay on the Home screen.

Character limits are Google's. Counts for this copy are at the bottom.

---

## App name

```
Atomshop - Pay in Steps
```

Unchanged: this is what the listing already carries (23 of 30 characters).
The Android manifest label is the shorter "Atomshop", which is correct — that
is the name under the launcher icon, not the store name.

---

## Short description

```
Buy phones, ACs, bikes and more on easy monthly installments. No credit card.
```

---

## Full description

```
Buy now. Pay in steps.

Atomshop is an installment shopping app. Browse phones, ACs, bikes, home appliances and more, see the exact monthly amount before you order, and pay in easy monthly installments. No credit card needed.

SEE THE REAL NUMBERS FIRST
Every product shows the advance, the monthly amount and the total before you place an order. Nothing is hidden and nothing is added later.

PLANS THAT FIT YOUR BUDGET
Start with a minimum 20% advance and choose a plan from 3 to 12 months.

0% MARKUP WITH ATOMPAY
Get your AtomPay limit once, using your CNIC and income details, then buy eligible products over 3 months with no advance and 0% markup. A processing fee and delivery charges apply. Your Atomshop login works on AtomPay too.

VERIFIED SELLERS IN YOUR AREA
Every seller is verified in person before they can take an order. A seller near you delivers to your door and sets up your plan there. Doorstep delivery is in Lahore today.

TRACK EVERY INSTALLMENT
See your active, pending and completed plans, every payment you have made, and a receipt for each one. You get a WhatsApp reminder when an installment is due, so nothing slips.

CANNOT FIND IT? ASK FOR IT.
• Custom order — want something from any shop? Enter the price and see the monthly plan straight away.
• Make an offer — not sure of the price? Tell us what you want and a seller calls you back.
• Ask Atom — ask about products, prices and plans and get an answer in the app.

WORKS WHEN YOUR SIGNAL DOES NOT
Make an offer, place a custom order or update your profile with no connection. Atomshop saves it on your phone and sends it the moment you are back online.

BROWSE WITHOUT AN ACCOUNT
Look around as a guest. You only need to sign in to place an order or track your installments.

ONE ACCOUNT, FOUR APPS
Atomshop for shopping, AtomPay for your purchase limit, Atom Seller for local sellers and AtomBrand for brands — one login across all of them.

Questions? Open Account and tap Contact.
```

---

## What's new (release notes for build 30)

```
• Offers, custom orders and profile changes now work offline. We save them on your phone and send them as soon as you are back online.
• AtomPay is now on the Home screen: get your limit and buy eligible products over 3 months with 0% markup.
• Clearer colours and text, consistent dialogs, and better focus feedback across the app.
```

---

## Before you paste this

Three things to decide.

**Delivery area — settled.** The product screen states "Delivery in Lahore
only" at checkout, so the listing now says Lahore too. Change that line the day
you open another city, and not before: a listing implying wider coverage than
you have is a listing-accuracy problem, and it is the kind of thing a
competitor reports.

**The AtomPay numbers — checked against the live app.** The running build on
2026-11-02 showed 3 to 12 month plans, a 20% minimum advance, and on the
AtomPay tab "3 months / No advance / 0% markup" with a 3% processing fee. The
server can still override the month count and the fee at runtime, so re-check
if you publish much later than this.

**Financial wording.** Everything above describes installments and a purchase
limit. Play reads the listing when it assesses the Financial features
declaration, and this is the same ground that got the iOS build rejected under
Guideline 2.3.1(a). Keep the listing and the Financial features declaration
saying the same thing.
