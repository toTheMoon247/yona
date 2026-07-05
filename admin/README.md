# Yona Admin (Edge Function + static UI)

Read-only admin view: all users on the left, click one → their subscriptions. It calls a
Supabase **Edge Function** (`supabase/functions/admin`) that (1) verifies your session,
(2) checks your email is in an admin allow-list, and only then (3) uses the `service_role`
key to read the data.

## Security model
- The **`service_role` key never leaves Supabase** — the Edge Function gets it from the
  platform at runtime. It's not on your machine, not in the browser, not in this repo.
- The UI holds only **public** values (project URL + anon key) in `admin/config.js`
  (gitignored). It signs you in with a **magic link** and passes your JWT to the function.
- The function rejects anyone whose email isn't in the `ADMIN_EMAILS` secret (403).

## One-time setup

### 1. Deploy the Edge Function (Supabase CLI)
```
supabase login                              # opens the browser
supabase link --project-ref <your-ref>      # from the Supabase dashboard URL
supabase secrets set ADMIN_EMAILS="you@example.com"   # your admin email(s), comma-separated
supabase functions deploy admin
```

### 2. Point the UI at your project
```
cd admin
cp config.example.js config.js
```
Fill `config.js` with your **Project URL** and **anon/public key**
(Supabase → Settings → API — *not* the service_role key).

### 3. Allow the magic-link redirect
In Supabase → **Authentication → URL Configuration**, add the URL you'll open the admin
page at (e.g. `http://localhost:5173`) to **Redirect URLs**.

## Run
Serve the static page locally (any static server; no Node project needed):
```
cd admin
python3 -m http.server 5173
```
Open **http://localhost:5173**, enter your admin email, click the magic link in your
inbox → you're in.

## What it shows
- **Users:** email, login provider (google / apple / email), subscription count, join date.
- **Per user:** each subscription's title, website, cost + cadence, billing source,
  payment method, and added date.

## Adding more admins later
`supabase secrets set ADMIN_EMAILS="you@example.com,other@example.com"` and redeploy is
not needed — secret changes apply to the running function.
