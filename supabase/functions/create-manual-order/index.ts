import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import {
  createServiceClient,
  getAuthenticatedUserId,
  normalizeGhPhone,
} from '../_shared/supabaseAdmin.ts';

interface ManualOrderPayload {
  items: Array<{ variant_id: string; quantity: number }>;
  customer_name: string;
  customer_phone: string;
  customer_whatsapp?: string;
  delivery_method: 'delivery' | 'pickup';
  delivery_zone_id?: string | null;
  region?: string | null;
  city?: string | null;
  address?: string | null;
  landmark?: string | null;
  notes?: string | null;
  mark_paid_immediately?: boolean;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const supabase = createServiceClient();
  const adminUserId = await getAuthenticatedUserId(req);
  if (!adminUserId) {
    return jsonResponse({ error: 'Authentication required' }, 401);
  }

  // Verify caller has admin role in profiles
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', adminUserId)
    .maybeSingle();

  if (profile?.role !== 'admin') {
    return jsonResponse({ error: 'Admin privileges required' }, 403);
  }

  try {
    const payload = (await req.json()) as ManualOrderPayload;
    const { data: rpcResult, error: rpcError } = await supabase.rpc(
      'create_order_with_reservation',
      {
        p_items: payload.items,
        p_customer_name: payload.customer_name,
        p_customer_phone: payload.customer_phone,
        p_customer_whatsapp: payload.customer_whatsapp ?? payload.customer_phone,
        p_delivery_method: payload.delivery_method,
        p_delivery_zone_id: payload.delivery_zone_id ?? null,
        p_region: payload.region ?? null,
        p_city: payload.city ?? null,
        p_address: payload.address ?? null,
        p_landmark: payload.landmark ?? null,
        p_notes: payload.notes ?? null,
        p_user_id: null,
        p_channel: 'whatsapp_manual',
      },
    );

    if (rpcError || !rpcResult) {
      return jsonResponse({ error: rpcError?.message ?? 'Failed to create manual order' }, 400);
    }

    const orderId = rpcResult.order_id as string;
    const orderNumber = rpcResult.order_number as string;
    const trackingToken = rpcResult.tracking_token as string;
    const totalGhs = Number(rpcResult.total);
    const reference = `${orderNumber}-WA-${crypto.randomUUID().slice(0, 6).toUpperCase()}`;

    await supabase
      .from('orders')
      .update({ paystack_reference: reference })
      .eq('id', orderId);

    const storeBase = (Deno.env.get('STORE_BASE_URL') || 'https://priscyluxury.com').replace(
      /\/$/,
      '',
    );
    const trackingUrl = `${storeBase}/track?order=${encodeURIComponent(orderNumber)}&token=${encodeURIComponent(trackingToken)}`;

    let paymentUrl = trackingUrl;
    const paystackSecret = Deno.env.get('PAYSTACK_SECRET_KEY');

    if (paystackSecret && !payload.mark_paid_immediately) {
      const cleanDigits = payload.customer_phone.replace(/[^0-9]/g, '');
      const paystackRes = await fetch('https://api.paystack.co/transaction/initialize', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${paystackSecret}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: `momo.${cleanDigits}@orders.priscyluxury.com`,
          amount: Math.round(totalGhs * 100),
          currency: 'GHS',
          reference,
          channels: ['mobile_money'],
          callback_url: `${storeBase}/order/confirmation?ref=${encodeURIComponent(reference)}&order=${encodeURIComponent(orderNumber)}&token=${encodeURIComponent(trackingToken)}`,
        }),
      });
      const paystackJson = await paystackRes.json();
      if (paystackRes.ok && paystackJson?.status) {
        paymentUrl = paystackJson.data.authorization_url;
      }
    } else if (payload.mark_paid_immediately) {
      await supabase.rpc('confirm_order', {
        p_reference: reference,
        p_amount_pesewas: Math.round(totalGhs * 100),
      });
    }

    const customerWa = normalizeGhPhone(
      payload.customer_whatsapp || payload.customer_phone,
    );
    const waText = payload.mark_paid_immediately
      ? `Hello ${payload.customer_name}, thank you for ordering from Priscy Luxury Slippers! Your order *${orderNumber}* (GHS ${totalGhs.toFixed(2)}) is confirmed. Track your delivery here: ${trackingUrl}`
      : `Hello ${payload.customer_name}, thank you for choosing Priscy Luxury Slippers! Your order *${orderNumber}* total is *GHS ${totalGhs.toFixed(2)}*. Please complete Mobile Money payment within 15 minutes to confirm your pair: ${paymentUrl}`;

    return jsonResponse({
      order_id: orderId,
      order_number: orderNumber,
      tracking_token: trackingToken,
      total: totalGhs,
      payment_url: paymentUrl,
      tracking_url: trackingUrl,
      whatsapp_url: `https://wa.me/${customerWa}?text=${encodeURIComponent(waText)}`,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Unable to create manual order';
    return jsonResponse({ error: message }, 500);
  }
});
