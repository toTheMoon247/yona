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

## 2. Optional cost tracking  _(idea — low effort, high value)_

An optional cost field per tile (amount + cadence: monthly / yearly). Empty =
no cost.

- Netflix → $15/month, Spotify → $12/month, Car insurance → $800/year, Bank → —
- Benefit: a "total monthly subscriptions" summary; surface recurring expenses.

Small schema addition (`cost_amount`, `cost_currency`, `cost_period`). Pairs well
with the broader "service" model in #3.

---

## 3. Revisit the Title + URL model  _(open decision)_

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

## 4. Modern tile actions  _(open decision; small to build)_

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

## Already tracked elsewhere (Future / Pro)

From the original spec, beyond the above: **Family Vault** (share tiles with
family), **Reminders** (renewals, expirations), **Emergency Access** (trusted
family access). See DESIGN §11.
