# Yona — Monetization Plan

Phased plan to add a **freemium model** to Yona, built per-platform but sharing one
backend entitlement so a purchase on either phone unlocks Premium everywhere.

## Model (proposed — pending final pricing)
- **Free:** up to **10 accounts**, logos, notes, search, open-website, basic cost field.
- **Premium ("Yona Premium"):** unlimited accounts · documents · renewal reminders
  (when built) · cost-breakdown · future Family Vault.
- **Plans:** monthly + yearly subscription **and** a one-time lifetime unlock.

## Tech choice: RevenueCat
One service wraps **StoreKit (iOS)** + **Google Play Billing (Android)**, validates
purchases, tracks subscription status, and gives a single cross-platform answer to
"is this user Premium?". Free until ~$2.5k/mo revenue. **One RevenueCat project,
two app integrations, one `premium` entitlement.** The RevenueCat app-user-id is set
to the **Supabase user id** on both apps — that's what makes entitlement cross-platform.

## Enforcement
- **Client:** paywall + gate the UI (block the 11th account, lock Documents).
- **Server (Supabase):** a RevenueCat webhook writes the entitlement to the DB; **RLS
  enforces the free limits** so a hacked client can't exceed them. This is the shared
  backend phase below — built once, serves both apps.

---

## Backend — Entitlement (shared, build once)
- **B1 — Entitlement store.** `profiles` (or `entitlements`) table: `user_id`,
  `is_premium`, `expires_at`, `product`. Default non-premium.
- **B2 — RevenueCat webhook.** A Supabase Edge Function receives RevenueCat events
  (purchase / renewal / cancellation / expiration) and upserts the row.
- **B3 — RLS limits.** Policy/trigger blocks inserting an 11th `tiles` row and any
  `attachments` row for non-premium users. Now the free limits are unbypassable.

---

## iOS — Monetization phases

### iM0 — Store & RevenueCat setup _(config; mostly you, I guide)_
- Apple **Paid Apps Agreement** + banking/tax in App Store Connect (**required before
  any IAP works**).
- Create a **subscription group** + products: `premium_monthly`, `premium_yearly`,
  and a non-consumable `premium_lifetime`.
- Create the **RevenueCat** project, add the iOS app, define the `premium` entitlement,
  attach the products, grab the iOS API key.

### iM1 — SDK + entitlement plumbing
- Add the RevenueCat **Purchases** SDK; configure with the API key.
- `logIn(supabaseUserId)` to RevenueCat so entitlement maps to the Yona account.
- An observable `EntitlementStore` exposing `isPremium`, injected like AuthStore.

### iM2 — Paywall UI
- A paywall screen: monthly / yearly / lifetime with live prices from RevenueCat,
  purchase flow, **Restore Purchases**, success → `isPremium` flips true (StoreKit sandbox).

### iM3 — Gating
- Block adding the 11th account → present the paywall.
- Lock **Documents** behind Premium → present the paywall.
- Surface an "Upgrade" entry (account menu / a subtle banner).

### iM4 — Polish & edges
- Restore on reinstall, expiry handling, "Manage subscription" link, grandfather
  existing >10-account users, paywall copy/design. _Milestone._

---

## Android — Monetization phases

### aM0 — Store & RevenueCat setup _(the slow/gated part)_
- **Google Play Console** account ($25 + **1–3 day identity verification**).
- Create the **subscription** (monthly/yearly base plans) + **one-time** lifetime
  product in Play Console.
- Add the Android app to the **same RevenueCat project**; connect Google via a service
  account; grab the Android API key. (Same `premium` entitlement as iOS.)

### aM1 — SDK + entitlement plumbing
- Add the RevenueCat Android SDK; configure with the API key.
- `logIn(supabaseUserId)` (same id as iOS → shared entitlement); expose `isPremium`.

### aM2 — Paywall UI
- A Compose paywall mirroring iOS: plans + live prices, purchase, **Restore**.

### aM3 — Gating
- Same free limits — block the 11th account, lock Documents, "Upgrade" entry.

### aM4 — Polish & edges
- Restore, expiry, manage-subscription deep link, grandfathering. _Milestone._

---

## Sequencing
1. **Now:** ship the current **free** build to **TestFlight** (no paywall) — Phase 5 Slice 2.
2. **Then start paywalls.** Kick off the slow account setup first and in parallel —
   **Google Play Console verification** (aM0) and **Apple Paid Apps Agreement** (iM0) —
   while building the paywall + gating code against RevenueCat test mode. By the time
   the accounts clear, the code is ready to plug into real products.
3. Build order once unblocked: **Backend B** → **iM1–3** / **aM1–3** in parallel → polish.

## Open decisions
- Subscription vs lifetime vs **both** (recommended: both).
- Final free/premium split (proposed: 10 free accounts + documents-are-premium).
- Pricing (ballpark: ~$2–3/mo, ~$15–20/yr, ~$40 lifetime).
- Grandfathering: existing users keep what they already created.
