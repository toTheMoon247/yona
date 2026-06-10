# Yona

A simple iPhone app to organize and remember your important online accounts and services in one place — Netflix, your bank, car insurance, Apple ID, etc. Each service is a **Tile** with a title, URL, optional notes, and attached documents, synced to the cloud.

> Status: **Design / pre-build.** No code yet. The full MVP design lives in [`docs/DESIGN.md`](docs/DESIGN.md).

## At a glance

| | |
|---|---|
| Platform | Native iOS, **SwiftUI**, iOS **17+** |
| Backend | **Supabase** (Postgres + Auth + Storage) |
| Auth | Google first; Apple Sign-In stubbed until Apple Developer enrollment |
| Logos | Logo API (Logo.dev/Brandfetch) with favicon + letter-tile fallback |
| Sync | Cloud, online-only (MVP) |

## Out of scope for MVP

Family sharing, reminders/notifications, categories, folders, password management, AI features, offline mode. See the design doc for the full Future / Pro list.
