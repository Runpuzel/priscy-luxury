import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { checkRateLimit } from '../_shared/rateLimit.ts';
import { createServiceClient, normalizeGhPhone } from '../_shared/supabaseAdmin.ts';

interface SubmitProofPayload {
  order_id?: string;
  order_number?: string;
  tracking_token?: string;
  phone?: string;
  txn_id: string;
  sender_name: string;
  sender_phone: string;
  screenshot_url?: string;
}

// Manual MoMo: customer pays seller directly, submits Transaction ID for verification.
Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return jsonResponse({ error: 'Method not allowed' }, 405);

  const supabase = createServiceClient();
  const allowed = await checkRateLimit(supabase, 'submit-payment-proof', req, 10, 5);
  if (!allowed) return jsonResponse({ error: 'Too many submissions. Please wait a few minutes.' }, 429);

  try {
    const body = (await req.json()) as SubmitProofPayload;
    if (!body.txn_id?.trim() || !body.sender_name?.trim() || !body.sender_phone?.trim()) {
      return jsonResponse({ error: 'Transaction ID, sender name and sender phone are required' }, 400);
    }
    let orderId = body.order_id;
    if (!orderId && body.order_number?.trim()) {
      const { data: order } = await supabase.from('orders').select('id, customer_phone')
        .eq('order_number', body.order_number.trim().toUpperCase()).maybeSingle();
      if (!order) return jsonResponse({ error: 'Order not found' }, 404);
      if (body.tracking_token?.trim()) {
        const { data: tokOrder } = await supabase.from('orders').select('id')
          .eq('id', order.id).eq('tracking_token', body.tracking_token.trim()).maybeSingle();
        if (!tokOrder) return jsonResponse({ error: 'Invalid tracking token' }, 403);
      } else if (body.phone?.trim()) {
        if (normalizeGhPhone(body.phone) !== normalizeGhPhone(order.customer_phone ?? '')) {
          return jsonResponse({ error: 'Phone does not match this order' }, 403);
        }
      }
      orderId = order.id;
    }
    if (!orderId) return jsonResponse({ error: 'order_id or order_number is required' }, 400);

    const { data, error } = await supabase.rpc('submit_manual_payment_proof', {
      p_order_id: orderId,
      p_txn_id: body.txn_id.trim(),
      p_sender_name: body.sender_name.trim(),
      p_sender_phone: body.sender_phone.trim(),
      p_screenshot_url: body.screenshot_url ?? null,
    });
    if (error) return jsonResponse({ error: error.message }, 400);
    return jsonResponse({ ok: true, message: 'Proof submitted! The seller will verify your payment shortly. You will be updated on WhatsApp.', result: data });
  } catch (err) {
    return jsonResponse({ error: err instanceof Error ? err.message : 'Unable to submit proof' }, 500);
  }
});
