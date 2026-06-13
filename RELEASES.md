# Releases

Milestone checkpoints for Yona. Each is an annotated, semver pre-1.0 git tag
(`v0.MINOR.0`) cut only at a **verified, CI-green** state — these are the
project's rollback points. `v1.0.0` is reserved for App Store launch. Newest first.

## v0.4.0 — MVP feature-complete · 2026-06-13

Polish pass — every feature in the MVP scope is now built.

- **Motion:** loading skeleton, animated tile add/remove, success haptics.
- **Instant home:** on-disk per-user cache renders the grid immediately on cold
  launch and survives offline; refreshes from the network.
- **App icon** — the blue 2×2 grid, matching the in-app logo.
- **Accessibility:** VoiceOver labels on tiles and the per-tile menu.

Built so far: auth, tile CRUD + search, logos, polish. Remaining before the App
Store: Apple Sign-In + TestFlight (Phase 5, needs Apple Developer enrollment).

## v0.3.0 — Logos · 2026-06-13

Real brand logos replace the letter-tile placeholders.

- **Brandfetch Logo API**: each tile shows its brand icon on a white circle (grid + detail).
- **Letter-tile fallback** while loading and for any brand Brandfetch doesn't recognize
  (`fallback/404` → clean miss, never a broken image).
- Logos **cache to disk** (larger shared `URLCache`) for instant loads on relaunch.
- **Domain extraction** (host minus `www`) as the lookup key, with unit tests.
- Config: `BRANDFETCH_CLIENT_ID` read from the git-ignored `Supabase.plist`.

## v0.2.0 — Tiles · 2026-06-13

The core of the app: users can manage their account tiles.

- **Home grid** of tiles (2 columns) with placeholder letter-logos and a note indicator.
- **Create, view, edit, delete** tiles. Detail screen with **Open Website** (in-app Safari).
- **Search** by title or URL (case- and diacritic-insensitive) with a no-results state.
- Loading / empty / error states throughout; pull-to-refresh.

Logos are still letter-tile placeholders — real brand logos arrive in Phase 3.

## v0.1.0 — Authentication · 2026-06-13

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
