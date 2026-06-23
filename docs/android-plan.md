# Yona for Android — Implementation Plan

The Android app (Kotlin + Jetpack Compose) mirrors the SwiftUI iOS app and shares
the **same Supabase backend** (accounts, logos, documents, RLS) — so a user's data
is identical on either phone. Built in the same slice-by-slice rhythm as iOS: each
slice builds, runs on the emulator, and is verified before commit. See
`implementation-plan.md` for the iOS plan and `roadmap.md` for product reasoning.

**Stack:** Kotlin 2.2.10, Jetpack Compose (Material 3), AGP 9.2.1, minSdk 24,
package `com.yona.app`. Backend via **supabase-kt 3.6.0** (Auth + Postgrest +
Storage). Config from a git-ignored `secrets.properties` → `BuildConfig`. Lives in
the monorepo under `android/`, with path-filtered CI (`android.yml`).

**Tags:** platform-prefixed — `android-v*` (iOS uses `ios-v*`; legacy unprefixed
`v0.x.0` tags are iOS). A milestone tag is cut at each phase end, verified + CI-green.

**No backend work remains** — schema, RLS, Storage, Google provider, and Brandfetch
are all live and shared with iOS. Every phase below is pure Compose app-code.

---

## Phase A0 — Foundations  _(✅ complete)_
supabase-kt wired; config plumbing (`secrets.properties` → `BuildConfig`); app
skeleton (`AppConfig`, `LoadState`, shared `Supabase` client); a connection-check
placeholder verified live against the backend.

## Phase A1 — Authentication  _(✅ complete — `android-v0.1.0`)_
Google sign-in via supabase-kt external-browser OAuth (redirect `yona://auth-callback`,
completed by the deep link in `MainActivity`); `AuthGate` routes on `sessionStatus`;
session persists across restarts; sign-out; disabled "Sign in with Apple" stub.

## Phase A2 — Tile CRUD  _(in progress → `android-v0.2.0`)_
The core loop. Letter-tile placeholders until Phase A3.
- **A2.1 — Read & grid** ✅ — `Tile` model, `fetchTiles`, 2-column grid with
  loading / empty / loaded / error states.
- **A2.2 — Create** ✅ — `+` FAB → title/url/notes form; `https://` auto-prepend; insert.
- **A2.3 — Detail** ✅ — tap a tile → title, URL, Open Website, notes (when present).
- **A2.4 — Edit & delete** ✅ — shared form for edit; delete with confirm; note dot on Home.
- **A2.5 — Search** — client-side filter on title + URL (case/diacritic-insensitive) + no-results.

## Phase A3 — Logos  _(→ `android-v0.3.0`)_
Real brand logos (Brandfetch Logo API) on grid + detail, with the letter-tile
fallback chain (never a broken image) and image caching (Coil). Domain extraction
as the lookup key. After this the app matches the mockup visually.

## Phase A4 — Polish & MVP feature-complete  _(→ `android-v0.4.0`)_
Loading skeletons, add/remove animation, haptics; instant-home on-disk cache (renders
the grid immediately on cold launch, then refreshes); app icon; accessibility pass
(TalkBack labels, large text).

## Phase A5 — Cost tracking  _(→ `android-v0.4.1`)_
Optional per-tile cost (amount + monthly/yearly); estimated monthly total on Home.

## Phase A6 — Renewal dates & sort  _(→ `android-v0.4.2`)_
Optional renewal date with recurrence (monthly/yearly, computed forward so it never
goes stale) + quick chips (today / +1 month / +1 year); Home sort menu (due date /
name / recently added / cost).

## Phase A7 — Smart add  _(→ `android-v0.4.3`)_
Service search (type "Netflix" → pick from results → autofill title/URL/logo via
Brandfetch Brand Search; manual entry remains) + the two-step add flow.

## Phase A8 — Document attachments  _(→ `android-v0.5.0`)_
Attach / preview / delete files on the detail screen, using the same private
Supabase Storage bucket + RLS as iOS (baseline storage; no client-side E2E). After
this phase the two apps are at **full feature parity**.

## Phase A9 — iOS v0.6 parity + polish  _(✅ → `android-v0.6.0`)_
Mirror the iPhone's v0.6 batch: optional URL (+ full-title circle), "how it's paid"
(billing source + payment method), the spend-hero header + brand mark, and the paywall
/ freemium gate (free up to 4 subscriptions; debug unlock). Plus a visual polish pass —
translucent search pill, modern rounded menus, iOS-style grouped-card add/edit form,
and a fixed brand-blue accent matching the app icon + iOS (dynamic color off). Apple
Sign-In has no Android analog (Google sign-in; Apple stubbed).

## Phase A10 — Play Store prep  _(→ `android-v0.7.0`)_
Signed release build, Play Console setup, internal testing track (the Android analog
of iOS's TestFlight). `v1.0.0` reserved for the public store launch.

---

## Parked (mirroring iOS)
- **Renewal reminders** — local notifications on the renewal date (no server needed). Unbuilt on both platforms.
- **Choose currency**, **tags on a tile**, **family / profile switching** — roadmap ideas, unbuilt on both. See `roadmap.md`.

## Status
**A0–A9 complete — Android matches iOS through the v0.6 feature set** (`android-v0.6.0`):
auth, tile CRUD, logos, polish, cost, renewal dates + sort, smart add, documents, plus
optional URL, "how it's paid", spend-hero header, the paywall, the grouped-card form,
and the brand-blue theme. Milestones tagged `android-v0.1.0` → `android-v0.6.0`.
Remaining: **A10 — Play Store prep** (signed build, Play Console, internal testing) →
`android-v0.7.0`. `v1.0.0` is reserved for the public store launches. Apple-gated work
(Apple Sign-In, TestFlight) is iOS-only and doesn't block Android.
