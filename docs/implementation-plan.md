# Yona — Implementation Plan

_Phase-by-phase task breakdown. **Confirm the current phase here before starting work.** Last updated: 2026-06-11._

> **This document covers the iOS app.** The Android app (Kotlin + Jetpack Compose,
> same Supabase backend) has its own plan — see [`android-plan.md`](android-plan.md).

Work is organized into **phases** (major capability areas) made of **slices** — each slice is a thin vertical cut that builds, runs, and is testable on its own, so the app is always in a demoable state. Milestone tags (`v0.MINOR.0`, per the Yentl convention) are cut at the end of a phase once it's verified and CI-green; `v1.0.0` is reserved for App Store launch.

**Scope note (2026-06-11):** **Document attachments are deferred to post-MVP (v1.x).** The MVP ships the core loop — remember an account → open its website → keep a note — with brand logos and polish. The `attachments` table and `documents` Storage bucket already exist in `supabase/schema.sql`, marked *reserved*, so v2 Documents is pure app-code work with no migration.

**Build order rationale:** get auth working, then the core tile loop (CRUD) with plain placeholders, then logos, then polish, then the Apple-gated work last (since it needs the paid Developer Program).

---

## Phase 0 — Foundations & Scaffolding
**Goal:** an Xcode project that builds in CI, talks to Supabase, and has the core architectural skeleton in place. No features yet.

- **Slice 1 — Xcode project.** Create the SwiftUI iOS 17 app, bundle id (`com.yona.app`), register the `yona://` URL scheme, add the `supabase-swift` package. App launches to a placeholder.
- **Slice 2 — Config & secrets.** `AppEnvironment` / `Backend` config reading the Supabase URL + publishable key from an ignored `Secrets.xcconfig` (never committed). Design tokens (colors, spacing, tile styling) as a small foundation.
- **Slice 3 — Architecture skeleton.** `LoadState<T>` enum, a `SupabaseRepository` wrapper, and empty `@Observable` stores (`AuthStore`, `TileStore`) injected via `.environment()`. Shared schemes committed.
- **Slice 4 — CI.** GitHub Actions building the app on a macOS runner + SwiftLint. Green before moving on.

_No tag (pre-v0.1.0)._

---

## Phase 1 — Backend Live & Authentication
**Goal:** a real Supabase project and Google sign-in working end-to-end; Apple stubbed.

- **Slice 1 — Stand up Supabase.** Create the project, run `supabase/schema.sql`, then the non-SQL config: register `yona://auth-callback` in URL Configuration, enable the Google provider, and a manual upload test to confirm the Storage `foldername` policy works live.
- **Slice 2 — Google sign-in.** `AuthStore` + repository auth calls; `signInWithOAuth(.google)` → `ASWebAuthenticationSession` → callback → session. `AuthGate` routes signed-out → `SignInScreen`, signed-in → `HomeScreen`.
- **Slice 3 — Session & sign-out.** Verify Keychain persistence + auto-refresh (cold launch restores session); `signOut()` from the account ••• menu; **Apple Sign-In stub** button (visible, disabled, behind a flag).

_Milestone: **`v0.1.0 — Authentication`**._

---

## Phase 2 — Tile CRUD (the core loop)
**Goal:** create, view, edit, delete, and search tiles — the heart of the app. Logos are letter-tile placeholders for now.

- **Slice 1 — Read & grid.** `Tile` model + repository `fetchTiles`; `HomeScreen` 2-column grid renders the user's tiles with a **letter-tile placeholder**. All four `LoadState` states wired (loading skeleton / empty CTA / loaded / error+retry).
- **Slice 2 — Create.** Floating "+" → `CreateTileSheet` (title, url, notes); light URL validation + `https://` auto-prepend; insert → new tile appears on Home.
- **Slice 3 — Detail.** Tap a tile → `TileDetailScreen`: title, URL, **Open Website** (`SFSafariViewController`), notes (shown only if non-empty).
- **Slice 4 — Edit & delete.** Reuse the form as `EditTileSheet` (from Detail + the per-tile ••• menu); delete with a confirm dialog; the note *indicator* shows on the Home tile when notes is non-empty.
- **Slice 5 — Search.** Client-side filter on title + URL (instant, diacritic-insensitive) + no-results state.

_Milestone: **`v0.2.0 — Tiles`**._

---

## Phase 3 — Logos
**Goal:** real brand logos on tiles, with a fallback chain that never shows a broken image. After this phase the app matches the mockup visually.

- **Slice 1 — Fallback foundation.** Formalize the **letter-tile generator** (first letter on a colored circle) and the **domain-extraction** helper (`https://www.netflix.com/x` → `netflix.com`), with tests.
- **Slice 2 — Logo API.** `LogoProvider` calls the chosen API (Logo.dev / Brandfetch — _verify free-tier terms first_); resolve once at create/edit and cache `logo_url` on the tile.
- **Slice 3 — Chain & caching.** Full fallback chain (API → apple-touch-icon → favicon → letter-tile); `AsyncImage` + `URLCache` for bytes; no re-resolve on scroll.

_Milestone: **`v0.3.0 — Logos`**._

---

## Phase 4 — Polish & MVP Feature-Complete
**Goal:** make it feel like a finished product.

- **Slice 1 — States & motion.** Audit every screen's loading/empty/error states; pull-to-refresh; transitions; haptics.
- **Slice 2 — Instant home.** Lightweight `Codable` cache of the tile list so Home renders instantly on cold launch, then refreshes (still online-only for writes).
- **Slice 3 — Identity & a11y.** App icon, launch screen, accessibility pass (Dynamic Type, VoiceOver labels), account/settings menu polish.

_Milestone: **`v0.4.0 — MVP feature-complete`**._

---

## Phase 5 — Apple Sign-In & Beta (Apple-gated)
**Goal:** the work that requires the paid Apple Developer Program — do it last.

- **Slice 1 — Enroll & flip Apple.** Enroll in the Apple Developer Program ($99/yr); add the Sign in with Apple capability; replace the stub with real `ASAuthorizationController` sign-in; enable the Apple provider in Supabase.
- **Slice 2 — TestFlight.** First signed build, App Store Connect setup, TestFlight beta with real users.

_Milestone: **`v0.6.0 — Beta`** (was v0.5.0; that became the Documents release). `v1.0.0` reserved for App Store launch._

---

## Additional feature phases (post feature-complete)

Built opportunistically after the MVP. Statuses reflect current intent; see
`docs/roadmap.md` for the product reasoning.

### Phase 6 — Renewal Dates & Sorting  _(✅ complete — v0.4.2)_
**Goal:** an optional renewal/due date per tile, surfaced and sortable.
- **Slice 1 — The field.** `renewal_date` column; `renewalDate` on `Tile` + `TileDraft`; an optional `DatePicker` in the form; show the date on the detail screen.
- **Slice 2 — Sort & surface.** Home sort menu (due date / name / recently added / cost); "renews in N days" hint.

### Phase 7 — Renewal Reminders  _(on hold)_
**Goal:** notify the user before a renewal, at a user-chosen lead time.
Local notifications (no server / no APNs — **not gated on the paid Apple program**), permission flow, per-tile scheduling, configurable lead time (day-of / 1 day / 3 days / week), auto-advance for recurring dates, reschedule/cancel on edit/delete. Depends on Phase 6's date field.

### Phase 8 — Document Attachments  _(✅ complete — v0.5.0)_
**Goal:** attach/view/delete documents on a tile, managed on the **Detail** screen.

**Storage decision (2026-06-12):** **Supabase Storage, baseline** — private bucket
+ RLS + provider-side at-rest encryption. *Not* iCloud, *not* client-side/E2E
encryption (the crypto is cheap but key-management + no-recovery UX isn't worth it
now, and E2E would make Family Vault sharing hard). Revisit only if "even we can't
read your files" becomes a headline feature.

- **Slice 1 — Attach & list.** `Attachment` model + repository (list/upload);
  `fileImporter`; 25 MB client cap; upload to `documents/{user_id}/{tile_id}/{uuid}-{name}`;
  insert row; "Attachments" section on Detail.
- **Slice 2 — Open / preview.** Signed URL → download to temp → QuickLook.
- **Slice 3 — Delete & cleanup.** Remove Storage object + row; sweep the tile's
  Storage folder on tile delete (cascade drops rows, not files); "N docs" count on Home.

Schema (`attachments` table + `documents` bucket + storage RLS) is already in
`schema.sql` — verify the bucket/policies exist and work on the first upload.

### Further ideas (not yet phased)
Title/URL model rethink (roadmap #3), Family Vault, Emergency Access, plus categories / folders / password management / AI / offline — see `docs/roadmap.md`.

---

## Status

**Phases 0–4 complete + post-MVP polish & cost tracking**, tagged through **`v0.4.1`**. **Phase 5 — Apple Sign-In & Beta is on hold pending Apple Developer Program enrollment** (currently *Pending*). **Phase 8 (Documents) complete** — tagged **`v0.5.0`**. Every non-Apple-gated feature is built (cost, renewals + recurrence, sort, service search, two-step add, documents). **Phase 5 — Apple Sign-In & Beta (now `v0.6.0`) on hold pending Apple enrollment.** Phase 7 (Reminders) + smaller ideas (#9–11) remain. **Next task chosen: cost breakdown screen (#8)** — tap the Home monthly total → per-account breakdown. See `project-manager-log.md` / `docs/roadmap.md`.
