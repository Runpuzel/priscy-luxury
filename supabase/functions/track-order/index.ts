import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { checkRateLimit } from '../_shared/rateLimit.ts';
import { createServiceClient, normalizeGhPhone } from '../_shared/supabaseAdmin.ts';

interface TrackOrderPayload {
  order_number?: string;
  phone?: string;
  tracking_token?: string;
  reference?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const supabase = createServiceClient();
  const allowed = await checkRateLimit(supabase, 'track-order', req, 20, 5);
  if (!allowed) {
    return jsonResponse({ error: 'Too many tracking attempts. Please wait a few minutes.' }, 429);
  }

  try {
    const body = (await req.json()) as TrackOrderPayload;

    // Optional: if customer just returned from Paystack redirect with ?ref=..., verify if still unpaid
    if (body.reference) {
      const paystackSecret = Deno.env.get('PAYSTACK_SECRET_KEY');
      if (paystackSecret) {
        const verifyRes = await fetch(
          `https://api.paystack.co/transaction/verify/${encodeURIComponent(body.reference)}`,
          { headers: { Authorization: `Bearer ${paystackSecret}` } },
        );
        const verifyJson = await verifyRes.json();
        if (verifyRes.ok && verifyJson?.data?.status === 'success') {
          await supabase.rpc('confirm_order', {
            p_reference: body.reference,
            p_amount_pesewas: Number(verifyJson.data.amount),
          });
        }
      }
    }

    let query = supabase
      .from('orders')
      .select(
        `
        id,
        order_number,
        channel,
        customer_name,
        customer_phone,
        delivery_method,
        region,
        city,
        subtotal,
        delivery_fee,
        total,
        status,
        payment_status,
        created_at,
        order_items (
          id,
          product_name,
          size,
          colour,
          unit_price,
          quantity
        ),
        order_events (
          id,
          status,
          note,
          created_at
        )
      `,
      );

    if (body.tracking_token?.trim()) {
      query = query.eq('tracking_token', body.tracking_token.trim());
      if (body.order_number?.trim()) {
        query = query.eq('order_number', body.order_number.trim().toUpperCase());
      }
    } else if (body.reference?.trim() && body.tracking_token?.trim()) {
      query = query.eq('paystack_reference', body.reference.trim());
    } else if (body.order_number?.trim() && body.phone?.trim()) {
      query = query.eq('order_number', body.order_number.trim().toUpperCase());
    } else {
      return jsonResponse(
        { error: 'Provide either tracking_token or order_number and phone' },
        400,
      );
    }

    const { data: order, error } = await query.maybeSingle();
    if (error || !order) {
      return jsonResponse({ error: 'Order not found. Check your order number and phone.' }, 404);
    }

    // Verify phone match when looking up without tracking_token
    if (!body.tracking_token?.trim()) {
      const providedPhone = normalizeGhPhone(body.phone ?? '');
      const storedPhone = normalizeGhPhone(order.customer_phone ?? '');
      if (!providedPhone || providedPhone !== storedPhone) {
        return jsonResponse({ error: 'Order not found. Check your order number and phone.' }, 404);
      }
    }

    // Mask customer phone in public tracking response
    const maskedPhone =
      order.customer_phone.length >= 6
        ? `${order.customer_phone.slice(0, 3)}****${order.customer_phone.slice(-3)}`
        : '***';

    return jsonResponse({
      order: {
        ...order,
        customer_phone: maskedPhone,
      },
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Unable to track order';
    return jsonResponse({ error: message }, 500);
  }
});
