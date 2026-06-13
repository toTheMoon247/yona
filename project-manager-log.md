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

## Day 3 — 2026-06-13

**Today.** Got login fully working — you can now sign into Yona with Google.

- **Connected the app to our cloud and to Google.** Set up the live database, turned on "Sign in with Google," and linked it all to the app.
- **Sign-in works start to finish.** Tapping "Continue with Google," approving in Google, and landing back in the app signed-in all works — tested on the simulator. (Hit one snag — the login was bouncing to the wrong page afterward — and fixed it.)
- **It remembers you.** Close and reopen the app and you're still signed in; signing out takes you back to the login screen. "Sign in with Apple" is shown but switched off until we join Apple's paid program later.
- **Saved a first official version.** Marked this as our first milestone — a safe point we can always return to.

**Where we are.** The app now has real, working login backed by the cloud. Next we build the actual content.

**Next steps (next day).** Start building the heart of the app: creating, viewing, editing, and deleting your account "tiles," and the home screen grid that shows them.

---

## Day 4 — 2026-06-13

**Today.** Built the heart of the app — you can now add and manage your accounts.

- **The home screen of tiles is live.** Your saved accounts show as a grid of cards, each with a colored placeholder logo and a little marker when it has a note.
- **Full add / open / edit / delete.** Tap "+" to add an account (name, website, optional note); tap a tile to see it and open its website inside the app; edit or delete any tile.
- **Search.** A search bar finds tiles by name or web address as you type, ignoring capital letters and accents.
- **Fixed a small bug** where clearing a note didn't stick — now it does.
- **Saved another official version** — our second milestone.

**Where we are.** The app is genuinely usable now: sign in and keep all your important accounts in one place. The logos are still simple letter placeholders.

**Next steps (next day).** Make it look polished by fetching the real brand logos (the Netflix "N," the Spotify circle, and so on) instead of the letter placeholders.

---

## Day 5 — 2026-06-13

**Today.** Replaced the plain letter placeholders with real brand logos.

- **Real logos.** Each account now shows its actual brand logo (Netflix's "N," Spotify's circle, Dropbox's box, and so on) instead of a colored letter.
- **Graceful fallback.** If a brand isn't recognized, the tile keeps its colored letter — so there's never a broken or blank logo.
- **Fast.** Logos are saved on the device after the first load, so they appear instantly next time.
- **Tidied up.** Removed an old leftover settings file we no longer use.
- **Saved another official version** — our third milestone.

**Where we are.** The app now looks the part — it matches the original mockup. Sign in, add accounts, and see real logos, all working.

**Next steps (next day).** A polish pass — smooth out the loading and empty screens, add an app icon, and improve accessibility — to get it feeling fully finished.

---

## Day 6 — 2026-06-13

**Today.** A polish pass — the app is now feature-complete for its first version.

- **Smoother and snappier.** Added a gentle loading placeholder, smooth animations when tiles are added or removed, and a success buzz (on a real phone) when you save or delete.
- **Instant open.** The app now remembers your accounts on the device, so it opens straight to your grid instead of loading from scratch — and it still shows them even with no internet.
- **App icon.** Yona now has its own icon — the clean blue grid that matches the logo inside the app.
- **Easier for everyone.** Improved support for VoiceOver (the screen reader) so the app is more accessible.
- **Saved our feature-complete version** — everything planned for the first release is now built.

**Where we are.** The app is done in terms of features: sign in, keep your accounts with real logos, search, all in a polished, fast experience.

**Next steps (next day).** The final stretch — set up Apple sign-in and get the app onto TestFlight so real people can try it. This is the part that needs the paid Apple developer account.

---

## Day 7 — 2026-06-13

**Today.** Put the app on a real iPhone, polished it from there, and added cost tracking.

- **On a real phone.** Installed Yona on the device and used it for real, which surfaced a bunch of small refinements.
- **Nicer logos and tiles.** Logos now appear instantly (no flicker), fill the tile, and sit cleanly without a white ring; tiles are bigger and less cluttered.
- **Modern actions.** Long-press a tile for Edit/Delete (the little three-dot button is gone).
- **Cost tracking (new).** You can add an optional monthly or yearly cost to any account, and the home screen shows your estimated monthly total.
- **Creation date.** Each tile shows when it was created, at the bottom of its detail screen.
- **Saved a checkpoint** capturing all of the above.

**Where we are.** A polished app running on a real phone, now with cost tracking. Still pre-beta.

**Next steps (next day).** A small code tidy-up, then the final stretch — Apple sign-in + TestFlight once the Apple developer account is sorted.
