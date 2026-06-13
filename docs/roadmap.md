# Yona — Roadmap & Product Notes

Post-MVP feature ideas and open product decisions. Captured from product
discussion on 2026-06-13. Nothing here is committed scope — it's the thinking.
For the built/planned phases, see `implementation-plan.md`.

---

## 1. Document attachments  _(planned — first post-MVP feature)_

Upload and store documents inside a tile (insurance PDFs, bank statements,
contracts, membership docs). Intentionally deferred from the MVP to keep the
first release simple; **highest-priority** future feature.

Status: the database schema (`attachments` table + private `documents` bucket +
RLS) is already shipped and reserved, so this is largely app-code work. See the
Phase plan / DESIGN §12.

---

## 2. Optional cost tracking  _(✅ shipped — v0.4.1)_

An optional cost field per tile (amount + cadence: monthly / yearly). Empty =
no cost.

- Netflix → $15/month, Spotify → $12/month, Car insurance → $800/year, Bank → —
- Benefit: a "total monthly subscriptions" summary; surface recurring expenses.

Small schema addition (`cost_amount`, `cost_currency`, `cost_period`). Pairs well
with the broader "service" model in #3.

---

## 3. Revisit the Title + URL model  _(partly handled by #7; open: optional URL)_

> **Update:** service search (#7) auto-fills title from the picked brand, so the
> "is Title redundant" half is effectively handled. **Still open:** making **URL
> optional** to support no-website records (local agent, private membership,
> offline service) — search doesn't change that the form still requires a URL.


**Today:** Title (required) + URL (required).

**Reframe:** the URL and Title do different jobs — the **URL powers the magic**
(logo + Open Website); the **Title is the human label**. "Both required" is wrong
in both directions: requiring a URL blocks offline records; requiring a typed
Title is redundant when a URL implies the name.

**Recommendation (assistant):** make **Title required, URL optional**, with the
Title **auto-suggested from the URL**.
- `netflix.com` → prefill "Netflix" (editable); logo + Open Website work.
- No website (insurance agent, private membership, offline service) → type a
  Title, skip URL → letter-tile logo, Open-Website button hidden.

**Cautions:**
- Don't fully remove Title (auto-only): derived names are imperfect
  (`bankleumi.co.il` → "Bankleumi", not "Bank Leumi") and users want to control
  the label ("Work Netflix"). Keep Title canonical; only *suggest*.
- This broadens Yona from *"online accounts"* → *"important accounts & services,
  online or not."* A stronger product, but a deliberate positioning choice.

Cost: small — `url` nullable, an auto-suggest helper, hide Open-Website when empty.

---

## 4. Modern tile actions  _(✅ shipped — v0.4.1: long-press context menu)_

**Today:** Edit/Delete via a visible ••• button on each grid tile.

**Note:** that ••• button now slightly clutters the clean logo-forward tiles.

**Recommendation (assistant):** replace ••• with a **long-press context menu**
(`.contextMenu`) — the native pattern (Photos / Files / App Library). Tap opens
the tile; long-press reveals Edit/Delete; the ••• disappears → cleaner tiles.
- **Skip swipe actions:** a list pattern, awkward on a 2-column grid. Revisit only
  if a list view is ever added.
- Tradeoff: discoverability (users must learn long-press) — mitigated by the strong
  iOS convention and Edit/Delete still living on the detail screen.

Small change; directly polishes the current redesign.

---

## 5. Renewal reminders  _(idea)_

Notify the user before a subscription/service renews, with **user-chosen timing**
(on the due day, 1 day before, 3 days, a week — configurable, maybe a global
default + per-tile override).

- Needs a new optional **renewal / next-due date** per tile (pairs naturally with
  cost tracking #2 → Yona becomes a lightweight subscription manager).
- **Likely local notifications** scheduled on-device from the known date — *no
  server / APNs needed*, so this is **not gated on the paid Apple program** (the
  app just needs notification permission). Simpler than push.
- This is the concrete design for the "Reminders" Future/Pro item (renewals,
  passport expiration, etc.).
- Open Qs: recurring dates (monthly/yearly) should auto-advance after each
  renewal; multiple reminders per tile; per-device scheduling from synced data.

## 7. Service search / smart add  _(✅ shipped — Brandfetch Brand Search)_

Instead of pasting a URL + typing a title, **search for a service by name** and
auto-fill everything.

- Type "netflix" → results list (logo + name + domain) → tap → title, URL, and
  logo auto-fill, **all still editable**.
- Powered by **Brandfetch's Brand Search API** — reachable with our existing
  client ID, and (per earlier research) in the **free tier** alongside the Logo
  API. Verify the exact endpoint + result quality before building.
- **Disambiguation** (the "Apple" problem): show matching brands as a **list**
  and let the user pick (apple.com vs icloud.com vs tv.apple.com). Keep fields
  editable after auto-fill, so they can pick "Apple" and rename to "Apple iCloud"
  while keeping the logo (logo follows the chosen domain).
- **Always keep a manual fallback** ("Can't find it / no website") → today's
  title + URL form, for niche brands, offline services, and custom records.
  Search OR manual, never search-only.
- This is the best implementation of the Title/URL rethink (**#3**) — fold #3
  into here. Effort: moderate (search UI + debounce + create-flow rework).

Open Qs: debounce timing; number of results; canonical name vs typed query.

## 6. Sort / arrange tiles  _(✅ shipped — v0.4.2)_

A sort option on the Home grid — notably **by due date** (soonest renewal first)
so upcoming charges float to the top.

- Needs the same **renewal/due date** field as #5.
- Make it a general sort menu: due date · name (A–Z) · recently added · cost —
  with due-date as the headline option.
- Could surface "renews in X days" on the tile or detail.

> **Shared foundation:** #5 and #6 both depend on adding an optional
> **renewal/due date** to a tile. Build that field once, then both layer on top.

---

## 8. Cost breakdown screen  _(idea)_

Tap the monthly-total summary on Home → a breakdown screen listing every tile
with a cost (normalized to monthly, sorted high → low) with the running total;
maybe a monthly/yearly toggle and each item's share of the total.

- **Low effort** — the data's already there (`monthlyCost` per tile); it's a new
  screen + making the existing Home summary tappable.

## 9. Choose currency  _(idea)_

Today the currency follows the device locale. Let the user pick the display currency.

- **App-wide setting = small** (one preference, applied in formatting). **Per-tile
  currency = much bigger** — mixing currencies breaks the monthly total, so it
  needs FX conversion + live rates. Recommend app-wide first; per-tile later.

## 10. Tags on a tile  _(idea)_

Freeform tags/labels for grouping + filtering on Home (e.g. "work", "family",
"streaming"). The MVP deliberately cut rigid categories/folders — **tags are the
lighter, more flexible take** (many per tile, no hierarchy).

- Needs a tags field + an add/edit UI + filter-by-tag on Home. Moderate effort.

## 11. Family members / profile switching  _(idea — big; this is "Family Vault")_

"These are *my* tiles → switch to **Mom's** tiles." A profile switcher across
several people's vaults.

- This is the concrete shape of the **Family Vault** item below. **Heaviest** of
  all the ideas: a multi-owner data model, sharing + permissions, RLS rework (who
  can see whose tiles), and an account-switcher UI. A real project, not a quick add.

---

## Already tracked elsewhere (Future / Pro)

From the original spec, beyond the above: **Family Vault** (share tiles with
family), **Reminders** (renewals, expirations), **Emergency Access** (trusted
family access). See DESIGN §11.
