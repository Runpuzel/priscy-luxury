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

    // 1. Atomically validate DB prices, validate stock, reserve for 15 min & create order
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
    const amountPesewas = Math.round(totalGhs * 100);

    const reference = `${orderNumber}-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;
    const baseUrl =
      payload.callback_base_url ||
      Deno.env.get('STORE_BASE_URL') ||
      'https://priscyluxury.com';
    const callbackUrl = `${baseUrl.replace(/\/$/, '')}/order/confirmation?ref=${encodeURIComponent(reference)}&order=${encodeURIComponent(orderNumber)}&token=${encodeURIComponent(trackingToken)}`;

    // Save Paystack reference before calling gateway
    await supabase
      .from('orders')
      .update({ paystack_reference: reference })
      .eq('id', orderId);

    const paystackSecret = Deno.env.get('PAYSTACK_SECRET_KEY');
    if (!paystackSecret) {
      return jsonResponse({ error: 'Payment gateway is not configured' }, 503);
    }

    // Paystack requires an email field; synthesize a deterministic customer receipt email if guest omitted email
    const cleanDigits = payload.customer_phone.replace(/[^0-9]/g, '');
    const customerEmail =
      payload.customer_email?.trim() || `momo.${cleanDigits}@orders.priscyluxury.com`;

    // 2. Initialize Hosted Paystack Transaction (GHS, Mobile Money channel only)
    const paystackRes = await fetch('https://api.paystack.co/transaction/initialize', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${paystackSecret}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: customerEmail,
        amount: amountPesewas,
        currency: 'GHS',
        reference,
        channels: ['mobile_money'],
        callback_url: callbackUrl,
        metadata: {
          order_id: orderId,
          order_number: orderNumber,
          customer_name: payload.customer_name,
          customer_phone: payload.customer_phone,
        },
      }),
    });

    const paystackJson = await paystackRes.json();
    if (!paystackRes.ok || !paystackJson?.status) {
      // Roll back stock reservation if Paystack failed to initialize
      await supabase.rpc('cancel_order_and_release_stock', {
        p_order_id: orderId,
        p_reason: 'paystack_init_failed',
      });
      return jsonResponse(
        { error: paystackJson?.message ?? 'Could not initialize Mobile Money checkout' },
        502,
      );
    }

    return jsonResponse({
      authorization_url: paystackJson.data.authorization_url,
      access_code: paystackJson.data.access_code,
      reference,
      order_id: orderId,
      order_number: orderNumber,
      tracking_token: trackingToken,
      subtotal: Number(rpcResult.subtotal),
      delivery_fee: Number(rpcResult.delivery_fee),
      total: totalGhs,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return jsonResponse({ error: message }, 500);
  }
});
