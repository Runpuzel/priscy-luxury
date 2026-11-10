import { SupabaseClient } from 'npm:@supabase/supabase-js@2';

export async function checkRateLimit(
  supabase: SupabaseClient,
  bucket: string,
  req: Request,
  maxRequests = 15,
  windowMinutes = 5,
): Promise<boolean> {
  const forwarded = req.headers.get('x-forwarded-for') ?? 'unknown';
  const ip = forwarded.split(',')[0].trim() || 'unknown';
  const since = new Date(Date.now() - windowMinutes * 60 * 1000).toISOString();

  const { count } = await supabase
    .from('rate_limit_logs')
    .select('id', { count: 'exact', head: true })
    .eq('bucket', bucket)
    .eq('identifier', ip)
    .gte('created_at', since);

  if ((count ?? 0) >= maxRequests) {
    return false;
  }

  await supabase.from('rate_limit_logs').insert({
    bucket,
    identifier: ip,
  });

  return true;
}
