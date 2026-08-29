# RAWNQ — Website & API Analysis

Analysis performed on **2026-08-29** against the live storefront.

- Storefront: <https://bring-us.app/rawnqgaza>
- Mobile storefront route: <https://bring-us.app/rawnqgaza/mobile>

Everything in this document was observed on the live site or returned by the
storefront's own publicly-readable API. **No product, price, category, size,
colour, delivery term or payment method in this repository was invented.**

---

## 1. Platform

`bring-us.app` is **BringUs**, a multi-tenant "WhatsApp e-commerce" SaaS.
RAWNQ is one tenant on that platform, addressed by the slug `rawnqgaza`.

| Property | Value |
| --- | --- |
| Front end | React SPA (Vite), client-side routed |
| Backend | Supabase (PostgREST + Edge Functions) |
| Supabase project | `lcqdchynunxhhajrtrql.supabase.co` |
| Media CDN | `https://dns.bring-us.app/<tenant_id>/...` |
| RAWNQ tenant id | `c4fb9d49-d756-4e94-991a-775c72bf7077` |
| RAWNQ slug | `rawnqgaza` |

The store is **not** a bespoke website, which matters: the visible feature set
is the platform's feature set intersected with what RAWNQ has actually
configured. Several platform features are present in the UI but hold no data
for RAWNQ (see §7).

## 2. Navigation map

The mobile storefront is the closest analogue to a phone app, so the Flutter
app mirrors its information architecture. Routes observed in the SPA router:

| Route | Arabic label | Reproduced in app |
| --- | --- | --- |
| `/mobile` | الرئيسية | Yes |
| `/mobile/categories` | الفئات | Yes |
| `/mobile/products/:categoryId` | — | Yes |
| `/mobile/product/:productId` | — | Yes |
| `/mobile/all-products` | كل المنتجات | Yes |
| `/mobile/products/new` | وصل حديثاً | Yes |
| `/mobile/brand/:brandId` | — | Yes |
| `/mobile/search` | البحث | Yes |
| `/mobile/favorites` | المفضلة | Yes |
| `/mobile/cart` | السلة | Yes |
| `/mobile/payment-selection` | — | Partly — see §6 |
| `/mobile/order-success` | — | Yes (local confirmation) |
| `/mobile/contact` | تواصل معنا | Yes |
| `/mobile/privacy` | سياسة الخصوصية | Yes (empty upstream — see §7) |
| `/mobile/terms` | الشروط والأحكام | Yes (empty upstream — see §7) |
| `/mobile/advertisements` | الإعلانات | No — no data upstream (§7) |
| `/mobile/orders`, `/mobile/account`, `/mobile/my-points`, `/mobile/settings` | الطلبات / الحساب | No — require platform accounts (§7) |

Bottom navigation on the live site: **الرئيسية · الفئات · السلة · الإعلانات ·
الطلبات · الحساب · الإعدادات**. The app ships the five that have real data
behind them.

## 3. Brand & store identity

Read from `tenants` where `slug = rawnqgaza`:

| Field | Value |
| --- | --- |
| `store_label` | `رونق \| RAWNQ` |
| `store_slogan_ar` | `لأنكِ تستحقين الأجمل` |
| `store_logo` | `https://dns.bring-us.app/tenant-assets/1782041147084-5wiafg8jui7.jpg` |
| `brand_color` | `#7c3918` (warm brown) |
| `country` | Palestine |
| `currency` | `ILS` (₪) |
| `tax_rate` | `0`, `prices_include_tax: true` |
| `timezone` | `Asia/Jerusalem` |
| `primary_language` | `ar` |
| `secondary_language` | `null` |
| `store_whatsapp` | `+970593208117` |
| `store_email` | `null` |
| `social_links.instagram` | `https://www.instagram.com/rawnqgaza/` |
| other social links | all empty strings |
| `show_stock_to_mobile` | `false` |
| `hide_out_of_stock_when_stock_hidden` | `false` |
| `mobile_discount_badge_style` | `percent` |
| `allow_mobile_self_registration` | `false` |
| `hide_prices_for_guests` | `false` |
| `privacy_policy_*`, `terms_conditions_*`, `about_us_*` | all empty |

**Consequences that shaped the app**

- `secondary_language` is null ⇒ the live store is **Arabic only**. Per the
  brief ("add English localization only if the existing website supports
  English") the app ships Arabic only, though the whole string layer is
  localisation-driven so English can be added by dropping in one ARB file.
- `show_stock_to_mobile: false` ⇒ never print stock counts. The app shows a
  binary **متوفر / غير متوفر** state instead.
- `hide_out_of_stock_when_stock_hidden: false` ⇒ out-of-stock items stay
  visible, greyed rather than hidden.
- `allow_mobile_self_registration: false` ⇒ no sign-up, no account area.
- Tax is 0 and included in prices ⇒ no tax line in the cart.

The logo is a real brand asset and is bundled at
`assets/brand/rawnq_logo.jpg` **unmodified**. It was not redrawn or recoloured.

## 4. Catalogue (live figures, 2026-08-29)

| Entity | Count |
| --- | --- |
| Categories | 4 |
| Brands | 3 |
| Active products | 47 |
| Product variants | 94 |

**Categories** (`categories`, ordered by `sort_order`)

| Order | Name | Products |
| --- | --- | --- |
| 0 | `قُمْصَان` | 4 |
| 1 | `لانجري` | 14 |
| 2 | `فساتين` | 1 |
| 3 | `بجامات` | 28 |

Each category carries an Arabic `description` and an `image` on the CDN.
`subcategories` is empty for this tenant.

**Brands** (`brands`): `تشارمي`, `لبنى`, `او لا لا` — each with a logo. 21 of
47 products are assigned a brand.

**Products** (`products`)

- Arabic names and long Arabic marketing descriptions (`name`, `description`;
  `name_ar`/`description_ar` mirror them).
- **Pricing lives in `price_1`, not `price`.** Every row has `price = 0` and a
  real value in `price_1` (the tier-1 retail price). Prices observed: 40, 45,
  60, 70, 80, 90, 100 ₪.
- `compare_at_price` is `null` on every product, `discount_percentage_tier1`
  is `0` on every product and `show_discount` is `false` on every product ⇒
  **nothing is currently discounted.**
- Images in flat columns `image_url_1` … `image_url_10` (the `images` array
  column is null). Distribution: 26 products with 1 image, 13 with 2, 5 with
  3, 2 with 4, 1 with 6. No product videos.
- `labels` is `["new"]` on 17 products, otherwise null. This drives the
  **جديد** badge and the "وصل حديثاً" listing.
- `is_featured` is false on every product ⇒ no featured rail upstream.

**Variants** (`product_variants`)

- 36 of 47 products have variants; the other 11 are single-option items.
- `attributes` is a JSON object. Observed keys: `color` (94/94),
  `color_hex` (94/94), `material` (94/94, always `قطن`), `size` (64/94).
- Sizes in use: `S`, `M`, `L`, `XL`, `XXL`, `XXXL`, `XXXXL`, `One Size`,
  `Big Size`.
- Colours mix English (`Beige`, `Dark Mocha`, `Green Sage`, …) and Arabic
  (`اسود`, `اخضر`, `توتي`). `color_hex` gives an exact swatch colour, so the
  app renders swatches rather than translating colour names.
- Variants carry their own `price_1`, `stock_quantity` and optional
  `image_url` (selecting a colour swaps the gallery image).
- 5 of 94 variants are out of stock.

**Stock.** The storefront calls the RPC `get_available_stock` and reads
`product_variants.stock_quantity`; `stock_mode` is `shared`.

## 5. Search, filtering, sorting

The site ships an `arabicSearch` module that normalises Arabic before
matching — stripping tashkeel, unifying أ/إ/آ→ا, ة→ه, ى→ي. The app
reimplements the same normalisation so that e.g. `قمصان` matches `قُمْصَان`.

Listing screens support category, brand and "new" filters plus price sorting.
There is no server-side full-text endpoint; filtering is client-side over the
fetched catalogue, which is small enough (47 products) for that to be correct.

## 6. Cart & ordering flow (the important part)

Traced through the live `MobileCart` bundle. The real sequence is:

1. Cart contents are priced through the **`cart-data` Edge Function**.
2. Stock is re-validated via `get_available_stock` before proceeding.
3. Guests must supply **name + mobile** (`allow_mobile_self_registration` is
   false, so essentially every shopper is a guest).
4. A **delivery location** must be selected.
5. A terms checkbox appears **only if** the tenant stores policy text. RAWNQ
   stores none, so the live cart shows no checkbox.
6. The cart builds an `orderData` payload and navigates to
   `/mobile/payment-selection`, which creates the order server-side.

**Delivery** (`delivery_locations`) — exactly one active row:

| Name | Type | Price |
| --- | --- | --- |
| `غزة` | `local` | `0.00` ₪ |

(The `tenant_locations` table the SPA also queries is empty for RAWNQ.)

**Payment methods** (`payment_methods`) — five active rows:

| Arabic | Type |
| --- | --- |
| `الدفع عند الاستلام` | `cod` |
| `الاستلام من المتجر` | `pickup` |
| `جوال باي` | `digital_wallet` |
| `بال باي` | `digital_wallet` |
| `بنك فلسطين` | `digital_wallet` |

The three wallet methods are **manual transfer instructions**, not integrated
gateways — no provider is configured on any of them. The platform does bundle
CyberSource and HyperPay checkouts, but RAWNQ has neither enabled.

### Why the app does not submit orders itself

Creating an order is a **write** into the BringUs production database using
BringUs's API key. That is well outside "read the public storefront", it is
not our data to write, and a stray automated order is a real-world cost to the
shop. So the app stops at a fully-native order review and then hands off:

- **واتساب** — opens `wa.me/970593208117` with a formatted Arabic order
  message (percent-encoded UTF-8). This matches the platform's own
  WhatsApp-commerce model and the number the store publishes on every page.
- **الموقع** — opens the official storefront cart in a secure in-app WebView
  so the shopper completes the real checkout on the real site.

No payment is ever processed in the app, and no payment method beyond the five
real ones above is offered.

## 7. Platform features present in the UI but empty for RAWNQ

Verified empty by direct query on 2026-08-29 — these are **not** implemented as
working features, and the app does not fake them:

| Table | Rows | UI affected |
| --- | --- | --- |
| `offers` | 0 | offer banners, countdowns |
| `promotions` | 0 | promo rules, free gifts |
| `popup_ads` | 0 | popup advertisement |
| `advertisements` | 0 | الإعلانات tab |
| `coupons` | 0 | coupon field in cart |
| `subcategories` | 0 | subcategory drill-down |
| `tenant_locations` | 0 | superseded by `delivery_locations` |
| `privacy_policy_ar` | empty | سياسة الخصوصية |
| `terms_conditions_ar` | empty | الشروط والأحكام |
| `about_us_ar` | empty | من نحن |

The app renders the policy screens against the live fields, so the moment the
shop fills them in they appear. Until then each shows an honest empty state
with a link to the published page on the website — it does not invent policy
text.

Loyalty points, order history, complaints, account statements and
notifications all require a platform customer account, which RAWNQ has
disabled. They are documented as future work, not shipped as stubs.

## 8. Typography, colour and visual identity

- Live site loads **Noto Sans Arabic**. The app uses **Cairo**, requested in
  the brief and a closer fit for a fashion brand while remaining a
  high-quality Arabic face.
- Brand colour `#7c3918`. The logo artwork supplies the surrounding palette:
  cream `#F3EBE1` ground, warm brown, muted terracotta.
- `mobile_theme` is `theme-2`; `show_bringus_branding` is true, so the app
  keeps the "مدعوم من BringUs" footer credit the website also shows.

## 9. Access & ethics notes

- Only the storefront's **public, anonymous, RLS-protected** read API was
  used — the same requests any visitor's browser makes.
- No authentication was bypassed, no private/admin endpoint was called, and no
  credential is stored in this repository.
- The platform's publishable `anon` key is **not committed**. It is read at
  runtime from configuration; see `docs/api-integration.md`.
- Nothing is written back to the platform.
