// Yona admin-login — public (no-JWT) magic-link gate.
//
// Runs BEFORE the admin has a session. Given an email, it sends a magic link ONLY if
// that email is in the ADMIN_EMAILS allow-list, and ALWAYS responds with the same
// generic message — so it never reveals who the admins are (no enumeration oracle).
// Non-admin emails trigger no email at all, which also protects the built-in email
// rate limit. Genuine send errors (e.g. rate limit) are surfaced so a real admin
// knows what happened.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } })

const GENERIC = 'If that email is an admin, a magic link has been sent — check your inbox.'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    const { email, redirectTo } = await req.json().catch(() => ({}))
    if (!email || typeof email !== 'string') return json({ error: 'Email required' }, 400)

    const admins = (Deno.env.get('ADMIN_EMAILS') ?? '')
      .split(',').map((s) => s.trim().toLowerCase()).filter(Boolean)

    // Not an admin → send nothing, but respond identically (no enumeration).
    if (!admins.includes(email.trim().toLowerCase())) {
      return json({ message: GENERIC })
    }

    // Admin → send the built-in magic-link email.
    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!)
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: typeof redirectTo === 'string' ? redirectTo : undefined },
    })

    // A send error (e.g. rate limit) only reaches here on the admin path; surface it
    // so a real admin gets useful feedback.
    if (error) return json({ error: error.message }, 429)

    return json({ message: GENERIC })
  } catch (e) {
    return json({ error: (e as Error).message }, 500)
  }
})
