# Releases

Milestone checkpoints for Yona. Each is an annotated, semver pre-1.0 git tag
(`v0.MINOR.0`) cut only at a **verified, CI-green** state — these are the
project's rollback points. `v1.0.0` is reserved for App Store launch. Newest first.

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
