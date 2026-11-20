import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { createServiceClient, getAuthenticatedUserId } from '../_shared/supabaseAdmin.ts';

interface CartLineInput {
  variant_id: string;
  quantity: number;
}

interface CreateOrderPayload {
  items: CartLineInput[];
  customer_name: string;
  customer_phone: string;
  customer_whatsapp?: string;
  customer_email?: string;
  delivery_method: 'delivery' | 'pickup';
  delivery_zone_id?: string | null;
  region?: string | null;
  city?: string | null;
  address?: string | null;
  landmark?: string | null;
  notes?: string | null;
  callback_base_url?: string;
}

// Manual MoMo only: registered customers create orders, pay seller directly,
// submit Transaction ID, seller verifies in Admin app. Stock reserved 24h.
Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  try {
    const payload = (await req.json()) as CreateOrderPayload;
    if (!Array.isArray(payload.items) || payload.items.length === 0) {
      return jsonResponse({ error: 'Cart is empty' }, 400);
    }
    if (!payload.customer_name?.trim() || !payload.customer_phone?.trim()) {
      return jsonResponse({ error: 'Customer name and Mobile Money phone are required' }, 400);
    }

    const supabase = createServiceClient();
    const userId = await getAuthenticatedUserId(req);
    if (!userId) {
      return jsonResponse(
        { error: 'You must register or sign in before making a purchase. Please create an account first.' },
        401,
      );
    }

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
        p_user_id: userId,
        p_channel: 'website',
      },
    );

    if (rpcError || !rpcResult) {
      return jsonResponse(
        { error: rpcError?.message ?? 'Unable to reserve stock and create order' },
        400,
      );
    }

    const orderId = rpcResult.order_id as string;
    const orderNumber = rpcResult.order_number as string;
    const trackingToken = rpcResult.tracking_token as string;
    const totalGhs = Number(rpcResult.total);
    const reference = `${orderNumber}-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;
    const baseUrl =
      payload.callback_base_url ||
      Deno.env.get('STORE_BASE_URL') ||
      'https://priscyluxury.com';

    await supabase
      .from('orders')
      .update({ paystack_reference: reference, payment_method: 'manual_momo' })
      .eq('id', orderId);

    await supabase
      .from('orders')
      .update({ reserved_until: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString() })
      .eq('id', orderId);

    return jsonResponse({
      payment_method: 'manual_momo',
      reference,
      order_id: orderId,
      order_number: orderNumber,
      tracking_token: trackingToken,
      subtotal: Number(rpcResult.subtotal),
      delivery_fee: Number(rpcResult.delivery_fee),
      total: totalGhs,
      manual_momo_number: '0550571248',
      manual_momo_name: 'Priscilla Adutwum',
      manual_momo_networks: ['MTN MoMo', 'Telecel Cash', 'AT Money'],
      instructions: 'Pay the exact total to the MoMo number above, then submit your Transaction ID on the next screen for seller verification.',
      tracking_url: `${baseUrl.replace(/\/$/, '')}/track?order=${encodeURIComponent(orderNumber)}&token=${encodeURIComponent(trackingToken)}`,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return jsonResponse({ error: message }, 500);
  }
});
