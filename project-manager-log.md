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

---

## Day 3 — 2026-06-12

**Today.** A marathon session — took Yona from "just foundations" all the way to a full-featured app running on a real iPhone. (It ran late, past midnight, but it's all one session.)

- **Login works.** Set up the live cloud backend and got "Sign in with Google" working end to end, with the session remembered across launches. (Saved our first official version.)
- **The core app.** Built the home screen of account "tiles" — add, view, edit, delete, and search your accounts.
- **Real logos.** Each account shows its real brand logo (Netflix, Spotify, and so on), with a clean colored-letter fallback when one isn't found.
- **Polish + on a real phone.** Smoothed the loading and empty screens, added animations and the app icon, and installed Yona onto an actual iPhone to carry around and use for real.
- **Cost tracking.** Give any account an optional monthly/yearly cost; the home screen shows an estimated monthly total.
- **Renewal dates.** Accounts can have a renewal date that repeats (monthly/yearly) and always shows the *next* one; sort the home screen by what's due soonest.
- **Search to add.** Instead of pasting a web address, type a brand name (e.g. "Netflix"), pick it from a list, and the name, link, and logo fill in automatically.
- **Cleaner add flow.** Adding an account is now two simple steps — pick the service, then add the optional details.
- **Document attachments.** Attach files to an account (insurance PDFs, statements…), open them in-app, and delete them; deleting an account cleans up its files too.
- **Saved several milestone versions** along the way, up to the Documents release.

**Where we are.** Yona is now a genuinely full-featured personal vault, running on a real phone: search-to-add accounts, real logos, costs, recurring renewal dates, sorting, and secure document storage. Everything that doesn't need an Apple developer account is built.

**Next task (next day): the cost breakdown screen.** Tap the monthly total on the home screen to open a screen that lists every account with a cost, shows what each costs per month, and the running total — so you can see exactly where the spend goes. (Apple sign-in + TestFlight is still waiting on the developer-account approval.)

---

## Day 4 — 2026-06-14

**Today.** Started building an Android version of Yona, so it works on Android phones too — not just iPhone.

- Set things up so both apps live together neatly without getting in each other's way.
- Built the Android app's foundation and connected it to the same backend as the iPhone app, so both share the same accounts and data. Got it running on an Android test phone.

**Where we are.** The iPhone app is finished and safely saved (version v0.5.0 — the point to return to if anything ever needs undoing). The Android app is just getting started: the groundwork is in place, but it has no features yet.

**Next steps (next day).** Add "Sign in with Google" to the Android app — its first real feature — reusing the login we already set up for iPhone.

---

## Day 5 — 2026-06-15

**Today.** Took the Android app from "just a shell" to genuinely usable — you can now log in and manage your accounts on Android, just like on iPhone.

- **Login works on Android.** Added "Sign in with Google" (stays logged in between uses; "Sign in with Apple" is a placeholder, same as iPhone). Saved as Android's first official version.
- **The accounts screen works on Android.** Built the home screen of account tiles — add, view, edit, delete, and search — the same core as the iPhone app. Saved as the second Android version.
- **Both apps stay in sync.** Because they share the same backend, an account added on one phone shows up on the other.
- **Wrote down the full Android plan** so the remaining steps (logos, polish, then matching the iPhone's extra features) are laid out.

**Where we are.** The iPhone app is finished and saved (v0.5.0). The Android app now has login plus the full accounts screen working on a test phone. It still shows simple colored-letter placeholders instead of real brand logos.

**Next steps (next day).** Add real brand logos to the Android app (Netflix, Spotify, and so on), with a clean fallback when a logo isn't found — after which the Android app will look like the finished iPhone app.

---

## Rest day — 2026-06-16

Day off — no coding today. Picking back up next session with brand logos on Android (Phase A3). _(Not counted as a work day, so the next coding session is Day 6.)_

---

## Day 6 — 2026-06-17

**Today.** Made the Android app look much closer to the finished iPhone one.

- **Real brand logos on Android.** Netflix, Spotify and the like now show their proper logos on the home grid, with a clean colored-letter circle as a fallback when a logo can't be found — just like the iPhone.
- **Started the visual polish.** Added the touches that make it feel finished: loading placeholders, pull-to-refresh, and smooth little animations. Saved a milestone version.

**Where we are.** Android now has a clean, logo-forward home screen that closely matches the iPhone. It's still missing the iPhone's extra features (costs, renewals, search-to-add, documents).

**Next steps (next day).** Finish the polish, then start adding the iPhone's extra features to Android one by one.

---

## Day 7 — 2026-06-18

**Today.** A big catch-up day — Android gained most of the iPhone's extra features.

- **Finished the polish** (app icon, instant-loading home screen, accessibility pass).
- **Added the extra features**, each saved as its own version: optional **cost tracking** with a monthly total; **renewal dates** (with monthly/yearly recurrence); **sorting** the home grid (by due date, name, cost…); and **search-to-add** (type a brand name and it fills in the name, website and logo).

**Where we are.** Android is almost at full feature-parity with the iPhone — only document attachments are left.

**Next steps (next day).** Add document attachments to Android, after which the two apps match.

---

## Day 8 — 2026-06-19

**Today.** Brought Android to full parity with the iPhone.

- **Document attachments on Android.** Attach, open and delete files on a subscription, using the same secure cloud storage as the iPhone.
- **Cleaner tiles** — switched to a long-press menu for Edit/Delete, matching the iPhone.

**Where we are.** The Android and iPhone apps now match feature-for-feature, sharing the same accounts and data. Everything that didn't need Apple's paid developer account is built on both.

**Next steps (next day).** Apple finally approved the developer account — so next is "Sign in with Apple" and getting the iPhone app onto TestFlight (Apple's tester system) so friends can try it.

---

## Day 9 — 2026-06-20

**Today.** Apple's developer account came through, and we shipped a big batch of new features.

- **Sign in with Apple** is now real on the iPhone (it was a placeholder before), and the iPhone app is **on TestFlight** — friends can install and test it.
- **A paywall plan.** The app is free for up to **4 subscriptions**; beyond that it offers a small upgrade (a low yearly price or a one-time payment). **Real payments aren't switched on yet** — the upgrade screen is in place for now.
- **A clear "what you pay" summary** on the home screen (your exact yearly total, split into monthly and yearly).
- **Renamed everything to "subscriptions"** for clarity, and added **"how it's paid"** — where a subscription is billed, plus an optional card type and last 4 digits only (never full card numbers).
- Saved this as the iPhone's **v0.6** version.

**Where we are.** The iPhone app is on TestFlight with the new features; friends can start testing. Android still needs to catch up on this batch.

**Next steps (next day).** Hand the iPhone build to testers; bring Android up to match the new features.

---

## Day 10 — 2026-06-21

**Today.** Acted on the first real-world feedback, brought Android fully up to date, and polished its look.

- **Your mum tried the app** and immediately hit a wall — she couldn't add her building maintenance fee because the app demanded a website. **Fixed it:** a website is now **optional**, and subscriptions without one show their **full name inside the circle**. Saved as **v0.6.1** and sent a fresh TestFlight build to testers.
- **Android caught up** with the whole recent batch: optional website + full-name circle, the yearly-spend summary, "how it's paid", and the paywall (free up to 4 subscriptions). Android matches the iPhone again on features.
- **Polished the Android look** so it feels as refined as the iPhone: a lighter, translucent search bar; modern rounded menus instead of plain gray boxes; and a redesigned add/edit form using the iPhone's grouped "cards" style.

**Where we are.** Both apps are full-featured and now look and feel alike. The iPhone is in friends-and-family testing on TestFlight (including family); Android is ready for its own store testing once the Google account verification finishes. Real payments and phone notifications are intentionally still switched off.

**Next steps.** Save the Android feature version; get Android into Google Play testing; later, switch on real payments (the billing service) and Apple push notifications.

---

## Rest day — 2026-06-22

Day off — no coding today.

---

## Day 11 — 2026-06-23 _(Today)_

**Today.** A small but visible colour fix, and Android's feature version is saved.

- **Made Android's blue match the iPhone.** The accent had been following the phone's wallpaper (a greyish blue); switched it to a fixed brand blue that matches the app icon and the iPhone, so it looks the same on every device.
- **Saved Android's feature version** (the equivalent of the iPhone's v0.6). Android is now fully caught up and polished, matching the iPhone.
- Also caught this project log up to date.

**Where we are.** Both apps are full-featured, look alike, and share the same data. The iPhone is in friends-and-family testing on TestFlight; Android is ready for its own store testing once the Google account verification finishes. Payments and phone notifications are still intentionally switched off.

**Next steps.** Get Android into Google Play internal testing; later, switch on real payments (the billing service) and Apple push notifications.

---

## Rest day — 2026-06-24

Day off — no coding.

---

## Day 12 — 2026-06-25

**Today.** A quick fix from a tester, plus some planning.

- **Fixed the "all-dark" look.** A friend opened the Android app on a phone set to dark mode and it came out mostly black (some colours weren't designed for a dark background). Made the Android app always use the clean light look, regardless of the phone's setting — matching the iPhone.
- **Planned the store rollout** — walked through the Google Play steps and what's still waiting (the Google account identity verification).

**Where we are.** Both apps are polished and matching. iPhone is in testing; Android is waiting on Google's verification.

**Next steps (next day).** Act on mum's feedback for the spending screen.

---

## Rest day — 2026-06-26

No coding — planning day (mum's spending-screen ideas and the payments/App-Store approach).

---

## Day 13 — 2026-06-27

**Today.** A round of improvements, mostly from mum trying the app.

- **Switch the total between per-month and per-year** on the home screen.
- **More billing schedules** — a subscription can now be weekly, every 2 months, quarterly, etc. (mum's building-maintenance bill is every 2 months, which the app couldn't handle before).
- **Friendlier choices** — replaced the little dropdowns with tap-to-pick "chips" so all the options are visible at a glance.
- **A new "Spending" breakdown screen** — tap the total to see every subscription sorted by cost, each with its share.
- Saved this as the iPhone's newest version, and made the upgrade button work for TestFlight testers so they can try beyond the free limit.

**Where we are.** The iPhone has the new spending tools; Android still to catch up.

**Next steps (next day).** Bring Android up to match.

---

## Day 14 — 2026-06-28

**Today.** Android caught up, and a product decision recorded.

- **Android got all the new spending tools** (month/year toggle, flexible schedules, chips, the breakdown screen). Saved as Android's matching version — the two apps are level again.
- **Decided *not* to build "auto-import your subscriptions from your bank / Netflix login."** It's either insecure (handing us your passwords) or doesn't work for Israeli banks — and typing a subscription in is quick anyway. Wrote the decision down so it's not revisited.

**Where we are.** Both apps full-featured and matching. Payments still off; both stores still pending.

**Next steps (next day).** A short break, then the store/payments setup.

---

## Break — 2026-06-29 → 2026-07-04

No coding — a few days off.

---

## Day 15 — 2026-07-05 _(Today)_

**Today.** Two nice additions, and kicked off the payments path.

- **Easier document attachments.** When adding a document you can now pick straight from **Photos** or **Files** — so attaching a screenshot no longer means saving it into Files first.
- **A private admin dashboard (for you).** A simple web page to see all your users and each one's subscriptions — behind a secure email magic-link login, with the sensitive keys kept inside the backend, never on your computer.
- **Started the App-Store payments setup** (via the billing service, RevenueCat) — but **parked it waiting on Apple** to approve the paid-apps agreement (their banking/tax check). Nothing more we can do until Apple comes back.

**Where we are.** Both apps are full-featured and matching. The iPhone is in testing; Android is awaiting Google verification. Real payments and the public App Store release are on hold pending Apple.

**Next steps.** When Apple approves, finish wiring up payments and submit the iPhone app to the App Store. Separately, get Android into Google Play testing once verified.

---

## Day 16 — 2026-07-06 _(Today)_

**Today.** Made the admin dashboard login simple and reliable.

- Yesterday's email-link login turned out flaky — the links kept coming back "expired." After ruling out the likely causes, we switched the admin login to a plain **email + password** instead. Much simpler and rock-solid, and the sensitive keys still stay inside the backend.

**Where we are.** The admin dashboard now works reliably. Both apps are still full-featured and matching; payments and the App Store release are still on hold pending Apple, and Android is awaiting Google verification.

**Next steps.** Wait on Apple (payments / App Store) and Google (Play verification).
