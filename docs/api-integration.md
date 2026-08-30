# RAWNQ — Data & API Integration

How the app gets its data, what it deliberately does not do, and how to switch
it from bundled data to the live storefront.

---

## 1. Two sources, one interface

`CatalogRepository` ([lib/shared/data/catalog_repository.dart](../lib/shared/data/catalog_repository.dart))
has exactly one method, and two implementations:

| Implementation | Source | `Catalog.isLiveData` |
| --- | --- | --- |
| `RemoteCatalogRepository` | Live storefront REST API | `true` |
| `LocalCatalogRepository` | `assets/data/catalog_snapshot.json` | `false` |

`catalogRepositoryProvider` picks between them at runtime:

```dart
final config = ref.watch(appConfigProvider);
if (!config.hasRemoteApi) return LocalCatalogRepository();
return RemoteCatalogRepository(client: ApiClient(config: config));
```

**With no configuration, the app runs on the bundled snapshot and says so** —
a banner reading `بيانات محلية للتجربة` sits above every catalogue screen,
carrying the snapshot date. Sample data is never presented as live data.

## 2. The live API

The storefront is a Supabase (PostgREST) backend.

- **Base URL**: `https://<project-ref>.supabase.co/rest/v1`
- **Auth**: the platform's publishable `anon` key, sent as both `apikey` and
  `Authorization: Bearer`. It is a public client key protected by row-level
  security — the same one the website ships in its JavaScript bundle.
- **Tenant scoping**: the shop is resolved by `slug`, and every subsequent
  request is filtered by the resulting `tenant_id`.

### Endpoints the app reads

All read-only `GET`s. Each is filtered to the tenant and to active rows.

| Table | Query | Used for |
| --- | --- | --- |
| `tenants` | `?select=*&slug=eq.<slug>&limit=1` | Store identity, branding, currency, WhatsApp, policies |
| `categories` | `?select=*&tenant_id=eq.<id>&is_active=eq.true&order=sort_order.asc` | الفئات |
| `brands` | same shape | Brand rail |
| `products` | same shape | Listings and detail |
| `product_variants` | same shape | Colours, sizes, per-variant price and stock |
| `delivery_locations` | `?select=*&tenant_id=eq.<id>&is_active=eq.true` | Delivery areas and fees |
| `payment_methods` | same shape | Payment options at checkout |

### Schema quirks the mapper handles

Two things in the live data will bite anyone who takes the columns at face
value, so they are normalised in the repository rather than leaking into the
models:

1. **`products.price` is `0` for every row.** The real retail price lives in
   `price_1` (the tier-1 price column). `RemoteCatalogRepository._normaliseProduct`
   copies it across before the model sees it.
2. **`products.images` is `null`.** Images are in flat `image_url_1` …
   `image_url_10` columns. `Product._images` reads the array when present and
   falls back to the flat columns otherwise.

Variant options are not columns either — they live in a JSON `attributes`
object with the keys `color`, `color_hex`, `size` and `material`.
`ProductVariant.fromJson` reads from either shape.

### Pagination

`ApiClient.selectAll` walks PostgREST's `offset`/`limit` range pagination in
pages of 500 until a short page comes back. The live catalogue is 47 products,
so this is one request today — but it stays correct if the shop grows.

### Timeouts, errors and caching

- Connect 12 s, receive 20 s, send 12 s.
- `DioException`s are mapped to a small `Failure` enum — `offline`, `timeout`,
  `server`, `notFound`, `unknown` — which the UI turns into distinct states
  (an offline screen is not the same as a server error).
- The parsed catalogue is cached in memory for 10 minutes.
  Pull-to-refresh calls `loadCatalog(forceRefresh: true)`.
- **Nothing personal is logged.** `Failure.detail` carries only a coarse label
  such as `http 500`; request URLs, headers and bodies are never logged.

## 3. Configuration

Nothing secret is committed. Values come from `--dart-define`:

| Key | Meaning |
| --- | --- |
| `RAWNQ_SUPABASE_URL` | `https://<project-ref>.supabase.co` |
| `RAWNQ_SUPABASE_ANON_KEY` | Publishable anon key |
| `RAWNQ_TENANT_SLUG` | Defaults to `rawnqgaza` |

See [.env.example](../.env.example) and [.env.example.json](../.env.example.json).

```bash
flutter run --dart-define-from-file=.env.json
```

```bash
flutter build apk --release --dart-define-from-file=.env.json
```

`AppConfig.hasRemoteApi` refuses anything that is not a complete `https` URL
plus a key, so a half-filled `.env` silently falling back to sample data
cannot happen — it either has a usable configuration or it does not.

### A note on whose key this is

The anon key belongs to **BringUs**, the platform, not to RAWNQ. It is public
by design, but shipping another company's API key inside a separate mobile
app is the platform operator's call, not ours. That is why the key is a
runtime input rather than a constant in the source. **Confirm with BringUs
before releasing a build that carries it.**

## 4. What the app deliberately does not do

- **It does not create orders through the API.** Order creation is a *write*
  into the platform's production database. That is out of scope for reading a
  public storefront, and a stray automated order costs the shop real money.
- **It does not scrape private endpoints, bypass auth, or store cookies,
  sessions or tokens.**
- **It does not process payments.** None of the shop's five payment methods is
  an integrated gateway; the app records the shopper's choice and passes it on.

## 5. How ordering works instead

`CheckoutScreen` collects and validates everything the shop needs — name,
phone, delivery area (from the live `delivery_locations`), payment method
(from the live `payment_methods`), notes — and then hands off two ways:

1. **WhatsApp.** `OrderDraft.toWhatsappUri` builds a `https://wa.me/<digits>`
   link with a formatted Arabic order message. `Uri.https` percent-encodes the
   UTF-8 correctly, which is verified by a test that asserts raw Arabic never
   appears in the encoded URL.
2. **The official web checkout.** `WebCheckoutScreen` opens the shop's own
   cart in a WebView pinned to the storefront host — a navigation attempt to
   any other host is refused rather than followed inside the app frame.

The cart is cleared **only after** the hand-off actually succeeds, so a failed
launch never loses the shopper's basket. The submit button disables itself
while in flight, preventing a double submission.

## 6. Security

- `ExternalLauncher` allows only `https`, `tel` and `mailto`. URLs arriving
  from remote data are parsed and scheme-checked before they are opened.
- The WebView restricts navigation to the storefront's own host.
- No credentials, cookies or tokens are stored on the device.
  `flutter_secure_storage` is not a dependency, because the app holds nothing
  that would warrant it.

## 7. The bundled snapshot

`assets/data/catalog_snapshot.json` (~132 KB) is a point-in-time copy of the
publicly readable storefront, captured **2026-08-29**: 4 categories, 3 brands,
47 products, 94 variants, 1 delivery area, 5 payment methods. Product imagery
is referenced by its CDN URL rather than embedded, so a first run still wants
a network connection for photos — `CachedNetworkImage` then caches them, and
failures fall back to a placeholder tile.

To refresh it, re-run the same public queries listed in §2 and rewrite the
file in the same shape. It is development data, not a live mirror; the app
never claims otherwise.

## 8. Not implemented (needs backend access the shop has not enabled)

Verified empty or disabled on the live tenant — documented as future work, not
shipped as non-functional stubs:

- Customer accounts and order history (`allow_mobile_self_registration: false`)
- Loyalty points, coupons, complaints, account statements
- Offers, promotions, popup ads, advertisements (all zero rows)
- Subcategories (zero rows)
- Push notifications
