# Project Manager Log

A daily journal of what we shipped, where the project sits, and what's next.

The MVP design (`README.md`, `docs/DESIGN.md`) and the decisions behind it were drafted on 2026-06-10. Unlike a pure planning day, that same session also stood up the repo and wrote the database schema, so it's counted as **Day 1**.

A "day" here is one work session, not one calendar day. If a session runs past midnight, the calendar rolls but the day in this log doesn't.

---

## Day 1 — 2026-06-10

**Today.** Turned the original one-page idea into a clear, agreed plan and set up the project's online home.

- **Agreed what the app is and how it works.** Settled the main choices: how login works (Google first, Apple later), how notes and logos behave, and which "nice-to-have" extras to leave out of the first version to keep it simple.
- **Wrote it all down.** Created the project's written plans — an overview, a full design document, and a step-by-step build plan — so anyone can see what we're building and in what order.
- **Prepared the database design.** Mapped out how accounts and files will be stored safely in the cloud, ready to switch on later.
- **Created the project's online home.** Set everything up on GitHub (our backup and history) so the work is saved and shareable.

**Where we are.** We have a complete, agreed plan and all the groundwork written down — but no actual app yet. Building it is next.

**Next steps (next day).** Start building the real app: set up the cloud database, create the iPhone app, and begin wiring up Google login.

---

## Day 2 — 2026-06-11

**Today.** Made one important decision and finished building the app's foundation.

- **Kept the first version simple.** Saving documents and files onto a tile is now planned for a later update, not the first release. The first version stays focused on the core idea: keep your important accounts in one place, open their website, and jot a quick note — with nice logos and a clean look. We've already laid the groundwork for documents behind the scenes, so adding them later will be easy.
- **Set up the app itself.** Created the real iPhone app, connected it to our cloud service, and put the basic internal structure in place. The app now opens and runs — for now it just shows a simple placeholder screen.
- **Added automatic quality checks.** Every time we save our work, the system now builds the app and checks it on its own — and everything is passing.

**Where we are.** The foundation is built, working, and safely backed up online. There's no login or real data yet — that's the next step.

**Next steps (next day).**

- **Turn on accounts and login.** Set up our cloud database and get "Sign in with Google" working from start to finish. ("Sign in with Apple" stays a placeholder button until we join Apple's paid developer program later on.)
- Once login works, this becomes our first official saved version of the app.
