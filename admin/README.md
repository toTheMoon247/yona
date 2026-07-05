# Yona Admin (Edge Function + static UI)

Read-only admin view: all users on the left, click one → their subscriptions. A local
static page signs in with **email + password**, then calls a Supabase **Edge Function**
(`supabase/functions/admin`) that verifies your session, checks your email is in an admin
allow-list, and only then uses the `service_role` key to read the data.

## Security model
- The **`service_role` key never leaves Supabase** — the Edge Function gets it from the
  platform at runtime. Not on your machine, not in the browser, not in this repo.
- The UI holds only **public** values (project URL + anon key) in `admin/config.js`
  (gitignored). It signs in with `signInWithPassword` — a single stateless call, no
  magic-link/redirect/hash flow.
- The `admin` function rejects anyone whose email isn't in the `ADMIN_EMAILS` secret (403),
  so even a valid non-admin session gets nothing.

## One-time setup
1. **Deploy the function + set the allow-list** (Supabase CLI, logged in + linked):
   ```
   supabase functions deploy admin
   supabase secrets set ADMIN_EMAILS="you@example.com"   # comma-separated for more admins
   ```
2. **Create the admin user** (Supabase → Authentication → Users → Add user): an email in
   `ADMIN_EMAILS` + a strong password, with **Auto Confirm User** checked. (If that email
   already exists as an OAuth user, set a password on it instead — a password can be added
   to an existing account without breaking its Google login.)
3. **Point the UI at your project:**
   ```
   cd admin && cp config.example.js config.js
   ```
   Fill `config.js` with the **Project URL** and **anon/public key** (Supabase → Settings →
   API — *not* the service_role key).

## Run
```
cd admin
python3 -m http.server 5173
```
Open **http://localhost:5173**, sign in with the admin email + password.

## What it shows
- **Users:** email, login provider (google / apple / email), subscription count, join date.
- **Per user:** each subscription's title, website, cost + cadence, billing source,
  payment method, and added date.
