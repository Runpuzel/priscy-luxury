import { jsonResponse } from '../_shared/cors.ts';
import { createServiceClient } from '../_shared/supabaseAdmin.ts';

Deno.serve(async (req: Request) => {
  const cronSecret = Deno.env.get('CRON_SECRET');
  const providedSecret =
    req.headers.get('x-cron-secret') ??
    req.headers.get('authorization')?.replace(/^Bearer\s+/i, '');

  if (cronSecret && providedSecret !== cronSecret) {
    return jsonResponse({ error: 'Unauthorized' }, 401);
  }

  const supabase = createServiceClient();
  const { data, error } = await supabase.rpc('release_expired_reservations');

  if (error) {
    return jsonResponse({ error: error.message }, 500);
  }

  return jsonResponse({
    ok: true,
    released_orders: data ?? 0,
    ran_at: new Date().toISOString(),
  });
});
