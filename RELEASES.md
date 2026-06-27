# Releases

Milestone checkpoints for Yona. Each is an annotated, semver pre-1.0 git tag
(`v0.MINOR.0`) cut only at a **verified, CI-green** state — these are the
project's rollback points. `v1.0.0` is reserved for App Store launch. Newest first.

Tags are platform-prefixed going forward — `android-v*` for Android, `ios-v*` for
iOS. The legacy unprefixed `v0.x.0` tags below are the iOS app.

## ios-v0.6.2 — iOS: Spending tools + flexible cadences · 2026-06-27

Mostly from mum's feedback. Build 5.

- **Spend total: Monthly/Yearly toggle** — flip the Home hero between "You pay £X a
  year" and "£Y a month" (remembered).
- **Flexible billing cadences** — Weekly · Monthly · Every 2 months · Quarterly ·
  Every 6 months · Yearly (her house-council bill is every 2 months), plus the
  matching "renews every…" recurrence. Spend totals annualize any cadence.
- **Chips instead of dropdowns** — Billing + Billed-through are now wrapping chips so
  every choice stays visible.
- **Cost breakdown screen** (roadmap #8) — tap the total → every subscription sorted
  high → low, with its real billing, normalized amount, and % share.
- **Paywall mock unlock works in TestFlight** too (still off in App Store production)
  so testers can go past the 4-subscription free limit.

Migration `0006` relaxes the cost_period / renewal_repeat checks. Android mirror of
the spending tools + cadences is pending.

## android-v0.6.0 — Android: iOS v0.6 parity + polish · 2026-06-23

Brings Android up to the iPhone's v0.6 feature set (mirroring `ios-v0.6.0` / `v0.6.1`),
plus a visual polish pass.

- **Optional URL** — a subscription no longer needs a website; no-website tiles show
  the full title fitted in the circle.
- **How it's paid** — billing source (App Store · Google Play · Direct · Bank · Other)
  + optional payment method (card type + last 4 only, non-store sources).
- **Spend-hero header** — "You pay $X a year" with the monthly/yearly split + per-bucket
  counts, plus the "Yona: Subscription Tracker" brand mark in the top bar.
- **Paywall + freemium gate** — free up to 4 subscriptions; a 5th opens an upgrade
  screen (yearly / lifetime placeholders). Real billing not wired yet (debug unlock).
- **Visual polish** — translucent search pill, rounded shadowed menus, iOS-style
  grouped "cards" add/edit form, and a fixed **brand-blue** accent (matches the app
  icon + iOS; Material You dynamic color off).

No new DB (migrations 0004/0005 already applied to the shared Supabase). Apple Sign-In
has no Android analog (Google sign-in; Apple stubbed). Next: Play Store prep →
`android-v0.7.0`.

## ios-v0.6.1 — iOS: Optional URL · 2026-06-21

A subscription no longer requires a website — the first real tester (a building
maintenance fee) hit the old "URL required" wall immediately.

- **URL is optional** in add & edit; only a Title is required.
- **No website → the full title fills the circle** (fitted, up to 3 lines) instead
  of a lone initial; the detail screen hides the host line + "Open Website" button.
- Tiles that have a URL are unchanged (brand logo, with the initial as fallback).
- DB migration `0005_optional_url` drops the non-empty-URL check (column stays
  NOT NULL, may be "").

Build 3 (version 1.0). Android mirror pending on `android-v*`.

## ios-v0.6.0 — iOS: Apple Sign-In, paywall & how-it's-paid · 2026-06-20

First prefixed iOS tag (continues from legacy `v0.5.0`). The TestFlight-ready batch:

- **Sign in with Apple** — native ID-token flow (CryptoKit nonce), replacing the stub,
  now that the Apple Developer Program is approved. Export-compliance flag declared.
- **Paywall + freemium gate** — free up to 4 subscriptions; the 5th opens a paywall
  (yearly / lifetime, placeholder prices). RevenueCat + real purchases come later;
  the buy action is a DEBUG dev-unlock for now. Existing subs are grandfathered.
- **Spend-hero header** — exact yearly total ("You pay $X a year") with the monthly /
  yearly split and a count per bucket; subtle "Yona: Subscription Tracker" brand mark.
- **"Subscriptions" rename** — user-facing "account"/"tile" → "subscription" app-wide.
- **How it's paid** — optional *Billed through* (App Store · Google Play · Direct ·
  Bank · Other) + optional *Payment method* (card type + last 4 only, never full
  numbers; shown only for non-store sources). DB migration `0004_payment_info`.

Build 2 (version 1.0) is archived from this tag. Android mirror of the paywall/header/
how-it's-paid is still pending on its own `android-v*` cadence.

## android-v0.5.0 — Android: Documents (full iOS parity) · 2026-06-19

Phase A8 — attach documents to a tile. **Android now matches the iOS feature set.**

- **Attach / open / delete** files on the detail screen, using the same private
  Supabase Storage bucket + RLS as iOS (baseline storage; no client-side E2E).
- Attach via the file picker (25 MB cap); open via download → external viewer
  (FileProvider `content://`); delete via a trash icon or long-press, with a
  confirmation dialog.
- Deleting a tile sweeps its Storage folder (the row cascade only removes rows).

**Android is now at full feature parity with iOS** — auth, tile CRUD, logos, polish,
cost, renewal dates + sort, smart add, and documents. `v1.0.0` is reserved for the
store launches.

## android-v0.4.3 — Android: Smart add (service search) · 2026-06-18

Phase A7 — search a brand by name to auto-fill an account.

- Type a brand (e.g. "Netflix") in the add flow → a debounced Brandfetch Brand
  Search shows results (logo + name + domain) → pick one to **auto-fill the title,
  website, and logo** (all still editable). Manual entry remains for anything it
  can't find.
- Integrated into the single add screen — Android keeps one screen rather than the
  iOS two-step wizard; the capability is the same.

## android-v0.4.2 — Android: Renewal dates & sort · 2026-06-18

Phase A6 — an optional renewal/due date per tile (with cost tracking, Android is now
a lightweight subscription tracker), plus Home sorting.

- Optional **renewal date** with recurrence (monthly/yearly, rolled forward so it
  never goes stale) — quick chips (today / +1 month / +1 year) and a date picker;
  shown on detail as "Renews <date> · in N days".
- Home **sort menu** (in the ⋮ menu): recently added / due date / name / cost,
  persisted across launches.
- Uses core library desugaring for `java.time` on minSdk 24.

## android-v0.4.1 — Android: Cost tracking · 2026-06-18

Optional per-tile cost — Android starting to catch up to the iOS post-MVP features.

- **Cost field** + a Monthly/Yearly selector in the add/edit form (optional; empty = no cost).
- **Detail** shows the cost; **Home** shows an "Estimated $X / month" total (yearly
  costs normalized to monthly). Costs set on iOS show here too (shared backend).
- Tolerant numeric decode (PostgREST may send `numeric` as a number or a string),
  mirroring the iOS flexible cost decode.

## android-v0.4.0 — Android: Polish (MVP feature-complete) · 2026-06-18

Phase A4 — polish. Android now matches the iOS MVP feature set.

- **States & motion:** loading skeleton, pull-to-refresh, animated tile add/remove,
  light haptics on save/delete.
- **Instant home:** a per-user on-disk cache renders the grid immediately on cold
  launch, then refreshes from the network.
- **Identity & accessibility:** app icon (the blue 2×2 grid, matching the in-app
  logo) and an accessibility pass — each grid tile is a single labelled, focusable
  element for TalkBack, with decorative logos and labelled icon buttons.

Android is now **MVP feature-complete** (auth, tile CRUD, logos, polish), matching
iOS `v0.4.0`. Next: the parity features (cost, renewals, smart add, documents).

## android-v0.3.0 — Android: Logos · 2026-06-17

Real brand logos replace the letter placeholders on Android (Phase A3), and the
grid is restyled to match the iOS app.

- **Brandfetch logos** on the grid + detail via Coil (cached in memory + on disk),
  with a fallback chain: Brandfetch → site favicon → colored letter tile (never a
  broken image). Domain extraction is unit-tested.
- **Tiles match iOS:** soft pastel rounded cards, the whole logo fit inside a circle
  with breathing room, title beneath — plus a subtle drop shadow and a modern pill
  search box (Android touches beyond iOS).
- **Detail screen** leads with the logo (bordered circle), the site host, and Open
  Website, with notes in a card.

Android now visually matches the iOS app. Next: polish (A4), then the parity features.

## android-v0.2.0 — Android: Tiles · 2026-06-15

The core loop on Android — full tile CRUD (Phase A2), all against the shared
Supabase backend (so accounts created on either phone appear on both).

- **Home grid** of the user's tiles (2 columns, colored letter placeholders, a note
  dot when notes is set) with loading / empty / loaded / error states.
- **Create, view, edit, delete** tiles: a `+` form (with `https://` auto-prepend), a
  detail screen with **Open Website**, a reusable add/edit form, and delete with a
  confirm dialog.
- **Search** by title or URL (case- and diacritic-insensitive) with a no-results state.

Logos are still letter-tile placeholders — real brand logos arrive in Phase A3. The
Android plan is now tracked in `docs/android-plan.md`.

## android-v0.1.0 — Android: Authentication · 2026-06-15

First milestone of the **Android** app (Kotlin + Jetpack Compose), sharing the
same Supabase backend as iOS.

- **Google sign-in end to end** (Supabase external-browser OAuth → `yona://auth-callback`
  deep link), verified on the emulator: app → Google approval → back into the app, signed in.
- **Session persists** across app restarts (SharedPreferences); **sign-out** returns
  to the sign-in screen.
- **Sign in with Apple** is present but disabled — a stub, same as iOS.
- Built on the Phase A0 foundation: supabase-kt 3.6.0, config via git-ignored
  `secrets.properties` → `BuildConfig`, and the `LoadState`/`AuthGate` skeleton.

## v0.5.0 — Documents · 2026-06-12

Attach documents to a tile — and the cap on a big run of post-MVP features.

- **Document attachments** (Phase 8): attach files to a tile (any type, 25 MB),
  open them in-app (QuickLook via signed URL), delete a single file, and sweep a
  tile's files when the tile is deleted. **Baseline Supabase Storage** (private
  bucket + RLS + at-rest encryption; no iCloud / no client-side E2E).
- Caps the post-`v0.4.0` run (cost tracking, renewal dates + recurrence, sort,
  service search, two-step add — `v0.4.1`–`v0.4.3`).

Every roadmap feature that doesn't need the Apple Developer account is now built.
Remaining: Apple Sign-In + TestFlight (now targeted at `v0.6.0`).

## v0.4.3 — Smart add & recurring renewals · 2026-06-12

- **Service search:** type a brand name → pick from results (logo + name + domain)
  → title / URL / logo auto-fill (Brandfetch Brand Search). Manual entry remains.
- **Two-step add flow:** Step 1 identifies the service (with a logo confirmation);
  Step 2 adds the optional details. Editing stays a single screen.
- **Recurring renewals:** a "Repeats" cadence (monthly / yearly / never) with the
  next occurrence computed forward so it never goes stale; Today / +1 month /
  +1 year quick chips (with a light haptic); smart default from the cost period.
  (Migration `0003_renewal_repeat.sql`.)

## v0.4.2 — Renewal dates · 2026-06-12

Phase 6: an optional renewal/due date per tile (with cost tracking, Yona is now
a lightweight subscription tracker).

- Optional **renewal date** in the form (toggle + date picker); shown on detail
  as "Renews <date> · in N days". (DB migration `0002_renewal_date.sql`.)
- Home **sort menu**: recently added / due date / name / cost (persisted).
- Plus an internal cleanup (TileDraft + detail-view split) — lint clean.

## v0.4.1 — Polish & cost tracking · 2026-06-12

Post-MVP refinements (mostly from using it on a real device) plus a new feature.

- **Cost tracking:** optional per-tile cost (amount + monthly/yearly) with an
  estimated monthly total on Home. (DB migration `0001_cost_tracking.sql`.)
- **Tile redesign:** large logos that fill the tile, title beneath, no in-tile clutter.
- **Logos:** instant (no flash) via an explicit loader + in-memory cache; fill the
  circle directly (no white backing).
- **Long-press context menu** for Edit/Delete (replaces the ••• button).
- **"Tile created <date>"** pinned at the bottom of the detail screen.
- Roadmap captured in `docs/roadmap.md`; SwiftLint CI fix.

## v0.4.0 — MVP feature-complete · 2026-06-12

Polish pass — every feature in the MVP scope is now built.

- **Motion:** loading skeleton, animated tile add/remove, success haptics.
- **Instant home:** on-disk per-user cache renders the grid immediately on cold
  launch and survives offline; refreshes from the network.
- **App icon** — the blue 2×2 grid, matching the in-app logo.
- **Accessibility:** VoiceOver labels on tiles and the per-tile menu.

Built so far: auth, tile CRUD + search, logos, polish. Remaining before the App
Store: Apple Sign-In + TestFlight (Phase 5, needs Apple Developer enrollment).

## v0.3.0 — Logos · 2026-06-12

Real brand logos replace the letter-tile placeholders.

- **Brandfetch Logo API**: each tile shows its brand icon on a white circle (grid + detail).
- **Letter-tile fallback** while loading and for any brand Brandfetch doesn't recognize
  (`fallback/404` → clean miss, never a broken image).
- Logos **cache to disk** (larger shared `URLCache`) for instant loads on relaunch.
- **Domain extraction** (host minus `www`) as the lookup key, with unit tests.
- Config: `BRANDFETCH_CLIENT_ID` read from the git-ignored `Supabase.plist`.

## v0.2.0 — Tiles · 2026-06-12

The core of the app: users can manage their account tiles.

- **Home grid** of tiles (2 columns) with placeholder letter-logos and a note indicator.
- **Create, view, edit, delete** tiles. Detail screen with **Open Website** (in-app Safari).
- **Search** by title or URL (case- and diacritic-insensitive) with a no-results state.
- Loading / empty / error states throughout; pull-to-refresh.

Logos are still letter-tile placeholders — real brand logos arrive in Phase 3.

## v0.1.0 — Authentication · 2026-06-12

First working slice: users can sign in.

- **Google sign-in end to end** (Supabase OAuth via `ASWebAuthenticationSession`),
  verified on the simulator: app → Google approval → back into the app, signed in.
- **Session persists** across cold launches (Keychain); **sign-out** returns to the
  sign-in screen.
- **Sign in with Apple** is present but disabled — a stub until Apple Developer
  Program enrollment (Phase 5).
- **AuthGate** routes between the sign-in screen and the placeholder home.

Backend: live Supabase project with the schema, RLS, Google provider, and the
`yona://auth-callback` redirect configured. App reads credentials from a
git-ignored, bundled `Supabase.plist`.
