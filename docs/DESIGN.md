# Yona — MVP Design

_Last updated: 2026-06-10. Captures the design decisions agreed during planning. Pre-build; no code exists yet._

## 1. Overview

Yona helps users organize and remember their important online accounts and services in one place. Each service is a **Tile** containing:

- **Title** (required)
- **URL** (required)
- **Notes** (optional, single free-text field)
- **Attached documents** (optional, multiple files)

Examples: Netflix, Bank Leumi, Car Insurance, Dropbox, Apple ID.

## 2. Locked decisions

| Area | Decision |
|---|---|
| Platform | Native iOS, SwiftUI, **iOS 17+** (use `@Observable` + plain views; skip heavy MVVM) |
| Backend | **Supabase** — Postgres + Auth + Storage |
| Auth | **Google first**; **Apple Sign-In stubbed** (button visible but disabled behind a flag) until Apple Developer Program enrollment ($99/yr) |
| Notes | **Option A** — single `text` column on `tiles`. Home shows a note *indicator* only when notes is non-empty (no count) |
| Logos | Logo API (**Logo.dev** or **Brandfetch**) behind a `LogoProvider` with fallback chain; resolved `logo_url` cached on the tile |
| Sync | Cloud, **online-only** for MVP |
| Search | **Client-side** filter on title + URL |
| Cut from MVP | Notification bell, grid edit mode |

### Default UX calls (changeable)
- Attachment preview: in-app **QuickLook**.
- URL validation: **light** (non-empty + looks like a host; auto-prepend `https://`). No reachability check.
- File size cap: **25 MB** per file, checked client-side.

## 3. Architecture

- **No heavy MVVM.** iOS 17 `@Observable` stores + plain SwiftUI views.
- One `@Observable` **store per concern** (`AuthStore`, `TileStore`) injected via `.environment()`.
- A thin **`SupabaseRepository`** wraps all SDK calls (DB / Storage / Auth). Stores never touch the SDK directly.
- Reusable **`LoadState<T>`** enum (`idle / loading / loaded(T) / failed(Error)`) drives every screen's loading/error/empty UI — the antidote to "online-only = blank screen."
- Optional lightweight **Codable cache** of the tile list for instant home load, then refresh.

### Cross-cutting components (build once, reuse)
- `LoadState<T>`
- `LogoProvider` — domain extraction + API + fallback chain + letter-tile generator
- `SupabaseRepository`
- File-type icon + size formatter
- Confirm-delete dialog

## 4. Data model (Supabase / Postgres)

All tables gated by **Row-Level Security** on `auth.uid()`.

```sql
-- tiles
id          uuid        primary key default gen_random_uuid()
user_id     uuid        not null    default auth.uid()        -- → auth.users
title       text        not null
url         text        not null
logo_url    text                                              -- resolved once at create/edit
notes       text                                              -- Option A: single field, nullable
created_at  timestamptz not null    default now()
updated_at  timestamptz not null    default now()

-- attachments
id            uuid        primary key default gen_random_uuid()
tile_id       uuid        not null references tiles(id) on delete cascade
user_id       uuid        not null default auth.uid()         -- denormalized for join-free RLS
filename      text        not null
storage_path  text        not null
content_type  text
size_bytes    bigint
created_at    timestamptz not null default now()
```

Notes:
- `user_id` is **denormalized** onto `attachments` so RLS/Storage policies are a trivial `user_id = auth.uid()` (no join).
- `on delete cascade` removes attachment **rows** when a tile is deleted, but **NOT** Storage objects — see §6.

## 5. Storage layout

- **Private** bucket.
- Path: `{user_id}/{tile_id}/{uuid}-{filename}` (uuid prefix avoids name collisions).
- Download via short-lived **signed URLs** (fetched on tap, not stored).
- Storage RLS policy keyed on the leading `{user_id}` path segment = `auth.uid()`.

## 6. Lifecycle gotchas

- **Tile delete must also delete the Storage folder** `{user_id}/{tile_id}/` — cascade only removes rows.
- **OAuth redirect** scheme `yona://auth-callback` **must** be registered in Supabase **URL Configuration → Redirect URLs**, or Google login silently fails. (Same trap hit on the Yentl project.)
- **Apple Sign-In** is a stub until Apple Developer Program enrollment; keep the `ASAuthorizationController` path dormant behind a flag and flip it on after enrolling.

## 7. Logos — `LogoProvider`

1. Extract the **registrable domain** from the user's URL (strip scheme, `www.`, path). e.g. `https://www.netflix.com/browse` → `netflix.com`.
2. **Primary:** Logo API (Logo.dev / Brandfetch) → image URL.
3. **Fallbacks:** site `apple-touch-icon` → Google favicon (`s2/favicons?sz=128`) → generated **letter-tile** (first letter on a colored circle). Never show a broken image.
4. Cache the resolved URL in `tiles.logo_url`; resolve once at create/edit, not per render. Let `AsyncImage` + `URLCache` handle bytes.

> TODO before build: verify Logo.dev / Brandfetch free-tier terms and rate limits against live docs.

## 8. Screens

### Navigation map
```
Launch
  └─ AuthGate (checks Supabase session)
       ├─ no session ──► SignInScreen
       └─ session ─────► HomeScreen
                            ├─ tap tile ──► TileDetailScreen ──► EditTileSheet
                            ├─ tap "+" ───► CreateTileSheet
                            └─ ••• menu ──► Edit / Delete
```
Single `NavigationStack`; Create/Edit are **sheets**; Detail is a **push**.

### SignInScreen
- Logo/wordmark + tagline.
- **Continue with Google** (live) and **Continue with Apple** (visible, disabled, "coming soon").
- States: idle / authenticating / failed (inline, retryable).

### HomeScreen (mockup, minus bell + Edit button)
- Top bar: "Yona" wordmark + single **•••** account menu (sign out; later settings).
- Search bar — client-side filter, instant, diacritic-insensitive.
- **2-column grid**. Each tile: logo (placeholder while loading/failure), title, footer row with **📄 N docs** (if >0) and a **📝 note indicator** (if notes non-empty — no count), and a per-tile **•••** menu (Edit, Delete w/ confirm).
- Floating **"+"** → CreateTileSheet.
- States: loading (skeleton / cache-then-refresh) · loaded+empty (friendly CTA) · loaded+results · failed (banner + Retry) · search-no-match.

### TileDetailScreen (push)
- Large logo + title.
- URL row + **Open Website** (`SFSafariViewController`).
- Notes section — shown only if non-empty.
- Attachments list — file-type icon, filename, size; tap → signed URL → **QuickLook**.
- Toolbar: **Edit** (sheet) and **Delete** (confirm → Home).

### Create / Edit Tile (sheet; one form, two modes)
- Fields: **Title** (req), **URL** (req; auto-prepend `https://`), **Notes** (optional multiline), **Attachments** (`fileImporter`: PDF, images, Word, Excel, etc.; staged+existing list, each removable; reject >25 MB).
- **Save** disabled until title + URL valid.
- On save: resolve `logo_url` (once) → upsert `tiles` → upload new files to Storage → insert `attachments` rows. Show progress; on failure keep sheet open with error (don't lose input).
- Edit extras: removing an existing attachment deletes its Storage object + row; deleting the tile cleans its Storage folder.

## 9. Suggested build sequence

1. Supabase project → schema + RLS + Storage bucket/policies → register `yona://` redirect.
2. `LoadState` + `@Observable` stores + `SupabaseRepository` skeleton + **Google auth** (Apple stubbed).
3. Tile CRUD + grid/detail/edit screens (letter-tile logo placeholder first).
4. Attachments (upload/download/size limits/cleanup) + real logo API + client-side search + polish.

## 10. Out of scope (MVP)

Family sharing, reminders, categories, folders, password management, AI features, offline mode.

## 11. Future / Pro

- **Family Vault** — share/manage Tiles for family members.
- **Reminders** — insurance/subscription renewals, passport expiration, etc. (this is what the mockup's 🔔 bell was for).
- **Emergency Access** — trusted family members access shared info when needed.
