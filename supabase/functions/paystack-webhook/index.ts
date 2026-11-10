import { createHmac, timingSafeEqual } from 'node:crypto';
import { Buffer } from 'node:buffer';
import { jsonResponse } from '../_shared/cors.ts';
import { createServiceClient } from '../_shared/supabaseAdmin.ts';

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const paystackSecret = Deno.env.get('PAYSTACK_SECRET_KEY');
  if (!paystackSecret) {
    return jsonResponse({ error: 'Missing PAYSTACK_SECRET_KEY' }, 500);
  }

  const rawBody = await req.text();
  const signature = req.headers.get('x-paystack-signature') ?? '';
  const expectedHex = createHmac('sha512', paystackSecret).update(rawBody).digest('hex');

  const sigBuf = Buffer.from(signature, 'utf8');
  const expBuf = Buffer.from(expectedHex, 'utf8');
  if (sigBuf.length !== expBuf.length || !timingSafeEqual(sigBuf, expBuf)) {
    return new Response('Invalid signature', { status: 401 });
  }

  const event = JSON.parse(rawBody);
  if (event.event !== 'charge.success') {
    return jsonResponse({ received: true, action: 'ignored' }, 200);
  }

  const reference = event.data?.reference as string | undefined;
  if (!reference) {
    return jsonResponse({ error: 'Missing transaction reference' }, 400);
  }

  // Secondary verification directly against Paystack API (defence in depth per Section 9)
  const verifyRes = await fetch(
    `https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`,
    {
      headers: { Authorization: `Bearer ${paystackSecret}` },
    },
  );
  const verifyJson = await verifyRes.json();
  if (
    !verifyRes.ok ||
    !verifyJson?.status ||
    verifyJson.data?.status !== 'success' ||
    verifyJson.data?.currency !== 'GHS'
  ) {
    return jsonResponse({ error: 'Transaction verification failed' }, 400);
  }

  const verifiedAmountPesewas = Number(verifyJson.data.amount);
  const supabase = createServiceClient();

  const { data, error } = await supabase.rpc('confirm_order', {
    p_reference: reference,
    p_amount_pesewas: verifiedAmountPesewas,
  });

  if (error) {
    return jsonResponse({ error: error.message }, 500);
  }

  return jsonResponse({ ok: true, result: data }, 200);
});
