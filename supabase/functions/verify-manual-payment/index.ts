import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { createServiceClient, getAuthenticatedUserId, normalizeGhPhone } from '../_shared/supabaseAdmin.ts';

interface VerifyPayload { order_id: string; approve: boolean; rejection_reason?: string; }

// Seller (admin) approves/rejects manual MoMo proof. Approve -> confirm + deduct stock.
Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return jsonResponse({ error: 'Method not allowed' }, 405);

  const supabase = createServiceClient();
  const adminId = await getAuthenticatedUserId(req);
  if (!adminId) return jsonResponse({ error: 'Authentication required' }, 401);
  const { data: profile } = await supabase.from('profiles').select('role').eq('id', adminId).maybeSingle();
  if (profile?.role !== 'admin') return jsonResponse({ error: 'Admin privileges required' }, 403);

  try {
    const body = (await req.json()) as VerifyPayload;
    if (!body.order_id) return jsonResponse({ error: 'order_id is required' }, 400);
    const { data, error } = await supabase.rpc('verify_manual_payment', {
      p_order_id: body.order_id,
      p_approve: body.approve,
      p_rejection_reason: body.rejection_reason ?? null,
    });
    if (error) return jsonResponse({ error: error.message }, 400);

    const { data: order } = await supabase.from('orders')
      .select('order_number, customer_name, customer_phone, customer_whatsapp, total')
      .eq('id', body.order_id).maybeSingle();
    let whatsappUrl = '';
    if (order) {
      const customerWa = normalizeGhPhone(order.customer_whatsapp || order.customer_phone);
      const waText = body.approve
        ? `Hello ${order.customer_name}, great news! Your manual MoMo payment for order *${order.order_number}* (GHS ${Number(order.total).toFixed(2)}) has been verified and confirmed. Your slippers are now being prepared. Track your order in the app. Thank you for shopping with Priscy Luxury Slippers!`
        : `Hello ${order.customer_name}, we could not verify the MoMo payment for order *${order.order_number}*. Reason: ${body.rejection_reason ?? 'Please check the amount and transaction ID.'} Please re-submit your proof in the app or message us on WhatsApp.`;
      whatsappUrl = `https://wa.me/${customerWa}?text=${encodeURIComponent(waText)}`;
    }
    return jsonResponse({ ok: true, result: data, whatsapp_url: whatsappUrl });
  } catch (err) {
    return jsonResponse({ error: err instanceof Error ? err.message : 'Unable to verify payment' }, 500);
  }
});
