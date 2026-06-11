# Project Manager Log

A daily journal of what we shipped, where the project sits, and what's next.

The MVP design (`README.md`, `docs/DESIGN.md`) and the decisions behind it were drafted on 2026-06-10. Unlike a pure planning day, that same session also stood up the repo and wrote the database schema, so it's counted as **Day 1**.

A "day" here is one work session, not one calendar day. If a session runs past midnight, the calendar rolls but the day in this log doesn't.

---

## Day 1 — 2026-06-10

**Today.** Took Yona from a one-page spec to a **public GitHub repo with the full MVP design and a paste-ready Supabase schema**. No app code yet — this was scoping + foundations.

Scoping & decisions (locked with the user):

- **Stack:** native SwiftUI, **iOS 17+** (`@Observable` + plain views, no heavy MVVM); backend **Supabase** (Postgres + Auth + Storage). Yona is a **separate app**, not part of Yentl.
- **Auth:** **Google first**; Apple Sign-In **stubbed** (visible-but-disabled button behind a flag) until Apple Developer Program enrollment ($99/yr).
- **Notes = Option A:** a single optional `text` field on the tile. Home shows a note *indicator* only when non-empty — no count. No notes table.
- **Logos** via a logo API (Logo.dev / Brandfetch) behind a `LogoProvider` with a fallback chain → apple-touch-icon → Google favicon → generated letter-tile. Resolved `logo_url` cached on the tile.
- **Cut from MVP:** the notification bell (Reminders are Future/Pro) and grid edit mode. Edit/delete happen from Tile Details + a per-tile ••• menu.
- Default UX calls (changeable): in-app QuickLook for attachments; light URL validation (auto-prepend `https://`); 25 MB per-file cap checked client-side.

Docs shipped:

- `README.md` (overview + at-a-glance table) and `docs/DESIGN.md` — the full blueprint: locked decisions, architecture (`LoadState<T>`, `@Observable` stores, `SupabaseRepository`), data model, Storage layout, lifecycle gotchas, the `LogoProvider` chain, every screen with its states, and the build sequence.

Database schema (`supabase/schema.sql`) — written, **not yet applied to a live Supabase project**:

- `tiles` + `attachments` tables (denormalized `user_id` on attachments for join-free RLS; indexes; title/url check constraints), `updated_at` trigger, full owner-only **RLS** on both tables, and a **private `documents` bucket** with per-user-folder Storage policies.
- Ends with a comment block listing the four things SQL can't enforce: register `yona://auth-callback`, enable the Google provider, delete Storage folders on tile-delete in app code, and the 25 MB cap.

Repo / process:

- `git init` on `main`, Swift/Xcode + secrets `.gitignore`, initial commit, then created the **public** GitHub repo and pushed: **https://github.com/toTheMoon247/yona**. Flagged the public-repo discipline (keep Supabase keys in ignored/local files; rotate anything leaked).

**Progress.** From "spec + mockup" to a public repo with a complete, agreed MVP design and a runnable schema. The schema has not touched a real Supabase project, there's no Xcode project, and there's no CI yet — all of that is Day 2.

**Steps for tomorrow.**

- **Stand up Supabase:** create the project, run `supabase/schema.sql`, then do the things SQL can't — register `yona://auth-callback` in URL Configuration, enable the Google provider, and a quick upload test to sanity-check the `storage.foldername(name)[1]` policy idiom live.
- **Verify the logo vendor:** check Logo.dev / Brandfetch free-tier terms and rate limits against their live docs before depending on one (open TODO in DESIGN §7).
- **Start Step 2 of the build sequence:** scaffold the Xcode project, add `supabase-swift`, build the `LoadState` + `@Observable` store + `SupabaseRepository` skeleton, and wire **Google auth** end-to-end (Apple stubbed).
- Adopt the Yentl conventions when the app exists: milestone `v0.MINOR.0` tags at verified, CI-green checkpoints + a `RELEASES.md`.

---

## Day 2 — 2026-06-11

**Today.** Settled the final scope cut (deferred Documents to v2) and built **all of Phase 0** — the app compiles, launches, and is green in CI on the first run.

Scope:

- **Deferred document attachments to post-MVP (v1.x).** MVP is now: remember account → open website → keep a note, plus logos + polish. The `attachments` table and `documents` bucket stay in `schema.sql` but are marked *reserved*, so v2 is pure app-code. Renumbered phases (Logos → 3, Polish → 4, Apple/Beta → 5); updated DESIGN / README / plan / schema.

Phase 0 — foundations (all 4 slices):

- **Xcode SwiftUI app** via the wizard (`com.yona.app`, iOS 17.6 floor, Swift Testing). Xcode 26.5 uses **file-system-synchronized groups**, so new source files join the target without editing `project.pbxproj`.
- **Supabase package (2.47.0)** linked to the target.
- **Architecture skeleton:** `AppConfig` (Info.plist-fed, placeholder-tolerant until Phase 1), `LoadState<T>`, `SupabaseRepository`, `@Observable` `AuthStore`/`TileStore` injected via `.environment()`, `DesignTokens`, minimal `Tile` model. A Phase 0 placeholder root confirms the wiring builds + launches.
- Committed a **shared scheme** (the wizard only makes a user scheme) so `xcodebuild`/CI can find the target.
- **CI:** GitHub Actions — build on `macos-15` + SwiftLint, both green first try; permissive `.swiftlint.yml`.

Hiccups (all resolved):

- Min deployment first stayed at **26.5** (wizard default = OS version); set to iOS **17.6** in General. _(17.6 not 17.0 — lower it for wider reach at the next Xcode-closed moment.)_
- "Add Package" added the supabase repo but didn't attach the **Supabase product** to the target → `Unable to resolve module dependency: 'Supabase'`. Fixed by adding the `Supabase` library under target → General → Frameworks.

**Progress.** **Phase 0 done** — app builds + launches, CI green (build + lint), public repo. No tag (Phase 0 is pre-`v0.1.0`). No backend yet — that's Phase 1.

**Steps for tomorrow.**

- **Phase 1 Slice 1 — stand up Supabase:** create the project, run `supabase/schema.sql`, register `yona://auth-callback` in URL Configuration, enable the Google provider, and a manual upload test for the Storage `foldername` policy. Wire real `SUPABASE_URL`/`SUPABASE_ANON_KEY` via `Secrets.xcconfig` → Info.plist (the xcconfig→plist wiring is a Phase 1 GUI step).
- **Phase 1 Slices 2–3 — Google sign-in** end-to-end (`AuthStore` + `AuthGate` routing), session persistence + sign-out, Apple stub button. Tag **`v0.1.0 — Authentication`** when verified + CI-green.
- Tracked minor: lower deployment target to 17.0; bump `actions/checkout` to v5 (Node 20 deprecation).
