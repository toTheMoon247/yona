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
