import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { checkRateLimit } from '../_shared/rateLimit.ts';
import {
  createServiceClient,
  getAuthenticatedUserId,
  normalizeGhPhone,
} from '../_shared/supabaseAdmin.ts';

interface SubmitReviewPayload {
  product_id: string;
  order_number: string;
  phone?: string;
  reviewer_name: string;
  rating: number;
  comment?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const supabase = createServiceClient();
  const allowed = await checkRateLimit(supabase, 'submit-review', req, 8, 10);
  if (!allowed) {
    return jsonResponse({ error: 'Too many review submissions. Please try again later.' }, 429);
  }

  try {
    const body = (await req.json()) as SubmitReviewPayload;
    if (
      !body.product_id ||
      !body.order_number?.trim() ||
      !body.reviewer_name?.trim() ||
      typeof body.rating !== 'number' ||
      body.rating < 1 ||
      body.rating > 5
    ) {
      return jsonResponse({ error: 'Missing or invalid review details' }, 400);
    }

    const userId = await getAuthenticatedUserId(req);

    // Look up paid order matching order_number
    const { data: order, error: orderErr } = await supabase
      .from('orders')
      .select('id, user_id, customer_phone, payment_status, order_items(product_id, variant_id)')
      .eq('order_number', body.order_number.trim().toUpperCase())
      .eq('payment_status', 'paid')
      .maybeSingle();

    if (orderErr || !order) {
      return jsonResponse(
        { error: 'Only verified buyers with a paid order can submit a review.' },
        403,
      );
    }

    // Verify ownership via authenticated user_id OR matching Mobile Money phone
    const isAccountOwner = Boolean(userId && order.user_id && order.user_id === userId);
    const isPhoneMatch = Boolean(
      body.phone &&
        normalizeGhPhone(body.phone) === normalizeGhPhone(order.customer_phone ?? ''),
    );

    if (!isAccountOwner && !isPhoneMatch) {
      return jsonResponse(
        { error: 'Order phone number did not match this purchase.' },
        403,
      );
    }

    // Confirm the order contains this product
    const items = (order.order_items ?? []) as Array<{ product_id: string | null; variant_id: string | null }>;
    let boughtProduct = items.some((i) => i.product_id === body.product_id);
    if (!boughtProduct) {
      const variantIds = items.map((i) => i.variant_id).filter(Boolean) as string[];
      if (variantIds.length > 0) {
        const { count } = await supabase
          .from('product_variants')
          .select('id', { count: 'exact', head: true })
          .in('id', variantIds)
          .eq('product_id', body.product_id);
        boughtProduct = (count ?? 0) > 0;
      }
    }

    if (!boughtProduct) {
      return jsonResponse(
        { error: 'This order does not include the selected footwear style.' },
        403,
      );
    }

    const { data: review, error: insertErr } = await supabase
      .from('reviews')
      .insert({
        product_id: body.product_id,
        order_id: order.id,
        user_id: userId,
        reviewer_name: body.reviewer_name.trim(),
        rating: Math.round(body.rating),
        comment: body.comment?.trim() ?? '',
        is_approved: false,
      })
      .select('id, created_at')
      .single();

    if (insertErr) {
      if (insertErr.code === '23505') {
        return jsonResponse({ error: 'You have already reviewed this item for this order.' }, 409);
      }
      return jsonResponse({ error: insertErr.message }, 400);
    }

    return jsonResponse({
      ok: true,
      message: 'Thank you! Your review has been submitted and awaits owner approval.',
      review,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Unable to submit review';
    return jsonResponse({ error: message }, 500);
  }
});
