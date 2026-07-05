// Yona admin — narrow, authenticated admin API.
//
// Security model, in order:
//   1. Verify the caller's Supabase session (JWT).
//   2. Authorize: the caller's email must be in the ADMIN_EMAILS allow-list secret.
//   3. Only then run a specific, named read action using the service_role client.
//
// SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY are injected by the
// platform — the service_role key lives only here, never on any client or dev machine.
// ADMIN_EMAILS is set with: supabase secrets set ADMIN_EMAILS="you@example.com"

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  })

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
    const ANON = Deno.env.get('SUPABASE_ANON_KEY')!
    const SERVICE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    // 1. Verify the caller from their JWT.
    const token = (req.headers.get('Authorization') ?? '').replace('Bearer ', '')
    if (!token) return json({ error: 'Missing session' }, 401)

    const caller = createClient(SUPABASE_URL, ANON)
    const { data: { user }, error: authErr } = await caller.auth.getUser(token)
    if (authErr || !user?.email) return json({ error: 'Invalid session' }, 401)

    // 2. Authorize against the admin allow-list.
    const admins = (Deno.env.get('ADMIN_EMAILS') ?? '')
      .split(',').map((s) => s.trim().toLowerCase()).filter(Boolean)
    if (!admins.includes(user.email.toLowerCase())) {
      return json({ error: 'Not authorized' }, 403)
    }

    // 3. Perform the requested action with the service_role client.
    const admin = createClient(SUPABASE_URL, SERVICE, {
      auth: { autoRefreshToken: false, persistSession: false },
    })
    const { action, userId } = await req.json().catch(() => ({}))

    if (action === 'list-users') {
      const users: Record<string, unknown>[] = []
      for (let page = 1; ; page++) {
        const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 200 })
        if (error) throw error
        users.push(...data.users)
        if (data.users.length < 200) break
      }

      const { data: tiles, error: tilesErr } = await admin.from('tiles').select('user_id')
      if (tilesErr) throw tilesErr
      const counts: Record<string, number> = {}
      for (const t of tiles) counts[t.user_id] = (counts[t.user_id] ?? 0) + 1

      const rows = (users as any[])
        .map((u) => ({
          id: u.id,
          email: u.email ?? u.phone ?? '(no email)',
          provider: u.app_metadata?.provider ?? 'email',
          created_at: u.created_at,
          last_sign_in_at: u.last_sign_in_at ?? null,
          subscriptions: counts[u.id] ?? 0,
        }))
        .sort((a, b) => +new Date(b.created_at) - +new Date(a.created_at))
      return json(rows)
    }

    if (action === 'user-tiles') {
      if (!userId) return json({ error: 'Missing userId' }, 400)
      const { data, error } = await admin
        .from('tiles')
        .select('id, title, url, cost_amount, cost_period, renewal_date, billing_source, payment_method, created_at')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
      if (error) throw error
      return json(data)
    }

    return json({ error: 'Unknown action' }, 400)
  } catch (e) {
    return json({ error: (e as Error).message }, 500)
  }
})
