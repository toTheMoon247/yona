# Releases

Milestone checkpoints for Yona. Each is an annotated, semver pre-1.0 git tag
(`v0.MINOR.0`) cut only at a **verified, CI-green** state — these are the
project's rollback points. `v1.0.0` is reserved for App Store launch. Newest first.

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
