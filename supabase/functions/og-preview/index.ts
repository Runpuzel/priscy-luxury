import { createServiceClient } from '../_shared/supabaseAdmin.ts';

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// Section 14.3: Per-product Open Graph preview generator for WhatsApp, Instagram & Facebook
Deno.serve(async (req: Request) => {
  const url = new URL(req.url);
  const slug = url.searchParams.get('slug') ?? '';
  const storeBase = (Deno.env.get('STORE_BASE_URL') || 'https://priscyluxury.com').replace(
    /\/$/,
    '',
  );

  const supabase = createServiceClient();
  const { data: product } = await supabase
    .from('products')
    .select('name, slug, description, base_price, product_images(url, sort_order)')
    .eq('slug', slug)
    .eq('is_active', true)
    .maybeSingle();

  const title = product
    ? `${product.name} — GHS ${Number(product.base_price).toFixed(2)} | Priscy Luxury Slippers`
    : 'Priscy Luxury Slippers — Premium Quality, Affordable Prices, Unbeatable Style!';
  const description =
    product?.description ??
    'Shop stylish, durable flat sandals, cushioned slides, and leather sandals across Ghana. Pay easily with Mobile Money.';
  const images = (product?.product_images ?? []) as Array<{ url: string; sort_order: number }>;
  images.sort((a, b) => a.sort_order - b.sort_order);
  const imageUrl =
    images[0]?.url ??
    'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=1200&q=80';
  const targetUrl = product ? `${storeBase}/product/${product.slug}` : storeBase;

  const html = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>${escapeHtml(title)}</title>
  <meta name="description" content="${escapeHtml(description)}" />
  <meta property="og:type" content="product" />
  <meta property="og:site_name" content="Priscy Luxury Slippers" />
  <meta property="og:title" content="${escapeHtml(title)}" />
  <meta property="og:description" content="${escapeHtml(description)}" />
  <meta property="og:image" content="${escapeHtml(imageUrl)}" />
  <meta property="og:url" content="${escapeHtml(targetUrl)}" />
  <meta property="product:price:amount" content="${product ? Number(product.base_price).toFixed(2) : '185.00'}" />
  <meta property="product:price:currency" content="GHS" />
  <meta name="twitter:card" content="summary_large_image" />
  <meta http-equiv="refresh" content="0;url=${escapeHtml(targetUrl)}" />
</head>
<body>
  <p>Redirecting to <a href="${escapeHtml(targetUrl)}">${escapeHtml(title)}</a>...</p>
  <script>window.location.replace(${JSON.stringify(targetUrl)});</script>
</body>
</html>`;

  return new Response(html, {
    status: 200,
    headers: { 'Content-Type': 'text/html; charset=utf-8' },
  });
});
