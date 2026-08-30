# RAWNQ · رونق

A Flutter shopping app for **RAWNQ (رونق)**, a women's clothing store in Gaza,
built to match the shop's live storefront at
<https://bring-us.app/rawnqgaza>.

Arabic-first, fully right-to-left, Android-primary with iOS supported.

---

## Contents

- [What this is](#what-this-is)
- [Features](#features)
- [Where the data comes from](#where-the-data-comes-from)
- [Architecture](#architecture)
- [Setup](#setup)
- [Running](#running)
- [Building](#building)
- [Testing](#testing)
- [iOS status](#ios-status)
- [Branding assets](#branding-assets)
- [Application identifiers](#application-identifiers)
- [Limitations and future work](#limitations-and-future-work)
- [Merge readiness](#merge-readiness)
- [Contributing](#contributing)

## What this is

RAWNQ sells on **BringUs**, a multi-tenant WhatsApp-commerce platform. The
shop is a tenant on that platform (slug `rawnqgaza`), not a bespoke website.
This app reproduces that storefront as a native experience: the same
catalogue, the same brand, the same Arabic copy, the same delivery and payment
options — with mobile-native browsing, an offline-capable cart, and persistent
favourites on top.

Everything the app displays was read from the shop's own public storefront.
**No product, price, category, size, colour, delivery term, payment method or
policy text was invented.** Where the shop has not configured something, the
app says so rather than filling the gap.

Full findings: [docs/website-analysis.md](docs/website-analysis.md).

## Features

**Implemented and working**

| Feature | Notes |
| --- | --- |
| Branded splash screen | Real logo on the brand cream ground |
| Home | Hero, category strip, brand strip, new arrivals, a rail per category |
| Categories | 4 real categories with Arabic descriptions and product counts |
| Product listing | Per category, per brand, all products, new arrivals |
| Product detail | Image gallery, colour swatches, size chips, description |
| Colour & size selection | Enforced before adding to the cart |
| Search | Arabic-normalised (finds `قُمْصَان` when you type `قمصان`) |
| Filters & sorting | Brand, availability, new; price/name/newest ordering |
| Favourites | Persisted between launches |
| Cart | Quantity stepper, stock ceiling, remove-with-undo, clear, persisted |
| Checkout | Validated form, real delivery area and payment methods, order summary |
| Order confirmation | With a reference the shopper can quote |
| WhatsApp ordering | Formatted Arabic message, correctly percent-encoded |
| Web checkout | The shop's own checkout in a host-pinned WebView |
| Contact | WhatsApp, phone, Instagram, website, store information |
| Privacy & terms | Rendered from the shop's own fields |
| States | Loading skeletons, offline, empty, error-with-retry, image fallbacks |

**Deliberately not implemented** — see
[Limitations](#limitations-and-future-work). These are documented as future
work, not shipped as non-functional stubs.

## Where the data comes from

The app has two interchangeable data sources behind one repository interface:

- **Live storefront API** — used when API configuration is supplied at build
  time. Reads the real catalogue over the storefront's public, read-only REST
  API.
- **Bundled snapshot** — the default. A point-in-time copy of the real public
  catalogue (`assets/data/catalog_snapshot.json`, captured 2026-08-29:
  4 categories, 3 brands, 47 products, 94 variants).

**When the snapshot is in use, every catalogue screen carries a banner saying
so, with the capture date.** Local data is never passed off as live.

Product photography always loads from the shop's CDN over the network, in both
modes, and is cached on device.

Full details, including the schema quirks the mapper handles and why the app
does not submit orders: [docs/api-integration.md](docs/api-integration.md).

## Architecture

Feature-first, with presentation, domain and data kept apart.

```
lib/
├── app/                 # Root widget, theme, router, shell, providers
├── core/
│   ├── config/          # Build-time configuration
│   ├── network/         # Dio client, timeouts, error mapping
│   ├── utils/           # Arabic normalisation, money, launcher, failures
│   └── widgets/         # Skeletons, state views, images, catalogue scaffold
├── features/
│   ├── home/            # Hero, category/brand strips, product rails
│   ├── categories/
│   ├── products/        # Listing, detail, filters, gallery, option selectors
│   ├── search/
│   ├── favorites/
│   ├── cart/
│   ├── checkout/        # Order draft, WhatsApp message, success
│   └── contact/         # Contact, policies, web checkout
├── l10n/                # Arabic ARB
└── shared/
    ├── data/            # Repository interface + remote and local sources
    └── models/          # Store, category, product, variant, cart, catalog
```

**Stack**

| Concern | Choice |
| --- | --- |
| State | `flutter_riverpod` |
| Navigation | `go_router` (shell route for the bottom bar) |
| Networking | `dio` |
| Images | `cached_network_image` |
| Persistence | `shared_preferences` (favourites, cart) |
| Platform links | `url_launcher`, `webview_flutter` |
| Localisation | `flutter_localizations` + `intl`, ARB-driven |

**Conventions**

- No visible string is hardcoded in a widget; everything resolves through
  `AppLocalizations`.
- Business rules live in models and controllers, not in `build` methods —
  e.g. option validation is in `CartController.add`, which is unit-tested
  independently of any widget.
- No code generation, so there is no `build_runner` step.

### Arabic and RTL

Arabic is the only language, because the live shop sets `primary_language: ar`
and no secondary language. The whole string layer is still ARB-driven, so
adding English is dropping in `app_en.arb` and widening `supportedLocales`.

- The tree is wrapped in `Directionality(TextDirection.rtl)`.
- Directional insets (`PositionedDirectional`, `EdgeInsetsDirectional`) are
  used so badges and chevrons sit correctly.
- Prices use Western digits with `₪`, matching the storefront.
- Text scaling is clamped to 0.85–1.4 so large system fonts cannot break the
  product grid; grid geometry additionally scales with the text scale factor.
- **Tajawal** is bundled offline rather than Cairo: Google Fonts distributes
  Cairo only as a variable font, whose weight axis Flutter's `fontWeight` does
  not drive, while Tajawal ships static instances that map cleanly to weights
  300–800. Both are named as acceptable in the brief. Licence:
  `assets/fonts/TAJAWAL-OFL.txt`.

## Setup

**Requirements**

- Flutter **3.47.2** stable or newer (Dart 3.13+)
- Android: JDK 17, Android SDK (`compileSdk` 35), an emulator or device
- iOS: macOS with Xcode 15+ and CocoaPods

```bash
flutter --version
```

```bash
flutter pub get
```

Localisations are generated by `flutter pub get`; to regenerate explicitly:

```bash
flutter gen-l10n
```

### Optional: point the app at the live API

Copy `.env.example.json` to `.env.json` and fill it in, then pass it at build
time. `.env.json` is git-ignored. Without it the app uses the bundled
snapshot. See [docs/api-integration.md](docs/api-integration.md) — including
the note on whose API key that is.

## Running

```bash
flutter run
```

Against the live API:

```bash
flutter run --dart-define-from-file=.env.json
```

## Building

**Android APK** (release, unsigned — see [identifiers](#application-identifiers)):

```bash
flutter build apk --release
```

**Android App Bundle** for Play:

```bash
flutter build appbundle --release
```

**Split per ABI**, for a smaller download:

```bash
flutter build apk --release --split-per-abi
```

**Debug APK**:

```bash
flutter build apk --debug
```

**iOS** (macOS only):

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode, set a signing team, and archive.
An unsigned build for CI:

```bash
flutter build ios --release --no-codesign
```

Release signing for Android needs a keystore and an `android/key.properties`.
**Neither is in this repository, and no signing key is generated by it** —
both paths are git-ignored.

## Testing

```bash
flutter test
```

With coverage:

```bash
flutter test --coverage
```

The suite covers models and parsing, Arabic search normalisation, price
formatting, filtering and sorting, cart calculations, product-option
validation, both repositories, the WhatsApp order message and its encoding,
and widget tests for the home screen, product detail, cart and a full
navigation flow.

Network access is faked at the `Dio` adapter and `AssetBundle` level, so
**no test depends on the live website being reachable.**

Analysis and formatting, as CI runs them:

```bash
flutter analyze
```

```bash
dart format --output=none --set-exit-if-changed lib test
```

CI: [.github/workflows/flutter-ci.yml](.github/workflows/flutter-ci.yml) —
analyze, format check and tests on every push, then an Android build that
uploads two artifacts:

| Artifact | What it is |
| --- | --- |
| `rawnq-debug-apk` | `app-debug.apk` |
| `rawnq-release-apk-debug-signed` | `app-release.apk`, **signed with the debug key** |

Flutter's generated Gradle config signs release builds with the debug keystore
when no release keystore is configured, so the second artifact installs and
runs but **must not be distributed**. A distributable build needs a real
keystore — see [Building](#building).

### Verified status

All results below are for commit **`5baba9d`**, the head of
`feature/flutter-shopping-app`.

| Check | Where | Result |
| --- | --- | --- |
| `dart format --set-exit-if-changed` | local + CI | clean, 67 files |
| `flutter analyze` | local + CI | **No issues found** — 0 errors, 0 warnings, 0 infos |
| `flutter test` | local + CI | **122 passed, 0 failed** |
| `flutter build apk --debug` | CI | success |
| `flutter build apk --release` | CI | success |
| Install and run on a physical Android device | maintainer | **passed** (reported by the maintainer, not reproduced in CI) |

Toolchain: Flutter 3.47.2 (stable), Dart 3.13.2 — the same version CI pins.

CI runs for that commit:
[push](https://github.com/Archipelago-alt/Rawnq/actions/runs/33305252190) ·
[pull_request](https://github.com/Archipelago-alt/Rawnq/actions/runs/33305253779).
Both are green on both jobs.

#### What the tested APK contained

The CI workflow passes **no `--dart-define` values and reads no secrets**, so
`AppConfig.hasRemoteApi` is false and the build falls back to
`LocalCatalogRepository`. The APK that was installed and tested therefore ran
on the **bundled catalogue snapshot** (`assets/data/catalog_snapshot.json`,
captured 2026-08-29), not on the live storefront API.

That is visible in the app itself: every catalogue screen shows the banner
`بيانات محلية للتجربة — لُقطة من المتجر بتاريخ …`. A build wired to the live
API shows no such banner. **No build produced so far has exercised the live
API path**; `RemoteCatalogRepository` is covered by unit tests against a fake
Dio adapter only.

#### Not yet verified

- **iOS has never been built.** No macOS or Xcode was available, so the iOS
  project is generated-and-configured but entirely uncompiled. See
  [iOS status](#ios-status).
- The live-API path has not been run against the real storefront from inside
  the app.
- No release signing has been exercised.

## iOS status

Both platform projects are committed: `android/` (47 tracked files) and
`ios/` (48 tracked files).

**Android is verified.** It builds in CI and has been installed and run on a
physical device.

**iOS is configured but unverified.** No macOS or Xcode was available at any
point, so nothing in the iOS project has ever been compiled. Specifically,
none of the following has been exercised:

| Item | State |
| --- | --- |
| Compilation (`flutter build ios` / `ipa`) | **Never run** |
| CocoaPods (`pod install`) | **Never run**; `ios/Podfile` is not present and is generated on the first iOS build |
| Bundle identifier `com.rawnq.gaza` | Written into `project.pbxproj`, never validated by a build |
| `CFBundleDisplayName` = `RAWNQ`, `CFBundleDevelopmentRegion` = `ar`, `CFBundleLocalizations` = `[ar]` | Written into `Info.plist`, not verified on device |
| `LSApplicationQueriesSchemes` (`https`, `tel`, `whatsapp`) | Written, not verified — this is what `url_launcher` needs for the WhatsApp and call actions |
| Launcher icons and native splash | Generated into the asset catalogues, never rendered by Xcode |
| RTL layout and the Tajawal font on iOS | Never seen running |
| `webview_flutter` (WKWebView) checkout hand-off | Never run |

Treat iOS as **unproven** until someone runs, on a Mac:

```bash
flutter pub get && cd ios && pod install && cd .. && flutter build ios --no-codesign
```

Expect to fix things there. Podfile generation and CocoaPods resolution in
particular have never been attempted for this dependency set.

## Branding assets

| Asset | Path | Status |
| --- | --- | --- |
| Logo | `assets/brand/rawnq_logo.jpg` | **Real**, downloaded unmodified from the shop's own CDN |
| Launcher icon | generated from the logo | Real |
| Splash | generated from the logo | Real |
| Catalogue snapshot | `assets/data/catalog_snapshot.json` | Real content, point-in-time |
| Tajawal font | `assets/fonts/` | SIL Open Font Licence |

The logo was **not** redrawn, recoloured or modified. The palette is the
shop's own: `brand_color` is `#7c3918` on the live tenant record, and the
cream (`#F3EBE1`) and terracotta (`#B5623C`) are sampled from the logo
artwork.

To replace the logo, overwrite `assets/brand/rawnq_logo.jpg` (square, ≥1024 px)
and regenerate:

```bash
dart run flutter_launcher_icons
```

```bash
dart run flutter_native_splash:create
```

A higher-resolution or transparent-background source (PNG/SVG) would give a
better adaptive icon than the current square JPEG; that is the one branding
improvement worth making when the shop can supply the original artwork.

## Application identifiers

| Platform | Identifier |
| --- | --- |
| Android | `com.rawnq.gaza` |
| iOS | `com.rawnq.gaza` |
| App name | `RAWNQ` |
| Arabic display name | `رونق` |

> **These identifiers are placeholders.** They were chosen to match the brief
> and could not be confirmed against any existing published RAWNQ app. Confirm
> with the shop before publishing — an ID cannot be changed after a Play Store
> release.

To change the Android ID, update `namespace` and `applicationId` in
`android/app/build.gradle.kts`, rename the `MainActivity.kt` package
directories to match, and update the `package` attribute if present in
`AndroidManifest.xml`. For iOS, set `PRODUCT_BUNDLE_IDENTIFIER` in
`ios/Runner.xcodeproj/project.pbxproj` (or via Xcode).

## Limitations and future work

**Reproduced from the live site**: catalogue, brand identity, Arabic copy,
delivery area, payment methods, category structure, product options, currency
and price formatting, Arabic search behaviour, navigation structure.

**Uses live data** when API configuration is supplied: everything above.
**Uses bundled development data** otherwise — labelled in-app.

**Not implemented, and why**

| Feature | Reason |
| --- | --- |
| Order submission to the platform | Requires *writing* to the platform's production database with the platform's key. The app hands off to WhatsApp or the official web checkout instead. |
| Payment processing | None of the shop's five payment methods is an integrated gateway. |
| Customer accounts, order history, loyalty points | The shop has `allow_mobile_self_registration: false`; there are no customer accounts to sign into. |
| Offers, promotions, coupons, advertisements | Zero rows on the live tenant. The UI supports discount badges, so a sale renders correctly the moment one exists. |
| Subcategories | Zero rows on the live tenant. |
| Push notifications | Needs backend access. |
| English localisation | The live shop is Arabic-only (`secondary_language: null`). |

**Known integration limitations**

- The bundled snapshot is a point in time; prices and stock drift until the
  live API is configured.
- Stock is read at add-to-cart time, so a long-lived cart can hold a line that
  has since sold out. The shop confirms availability when it receives the
  order — as it does for web orders too.
- Product images always require the network on first view.
- Privacy policy and terms are empty upstream; those screens show an honest
  empty state and link to the website, rather than inventing legal text.

## Merge readiness

These two lists are deliberately separate: what stands in the way of merging
this branch, and what would be needed before the app reaches real shoppers.

### Blocking the merge

Nothing in the automated checks. As of `5baba9d`, format, analyze, tests and
both Android builds pass, and Android has been verified on a device.

What a reviewer should still decide, because these are judgement calls rather
than defects:

| # | Decision | Why it needs a human |
| --- | --- | --- |
| 1 | Confirm the application ID `com.rawnq.gaza` | It is a **placeholder**; it could not be confirmed against any published RAWNQ app, and it can never be changed after a Play Store release. |
| 2 | Accept that checkout hands off rather than submitting orders | The alternative writes to the BringUs production database with the platform's key. Deliberate; see [Where the data comes from](#where-the-data-comes-from). |
| 3 | Accept iOS as unbuilt | See [iOS status](#ios-status). Merging is still reasonable if iOS is treated as work in progress. |
| 4 | Accept the base branch | `main` was created solely to give this PR a target; the repository was empty. |

### Required before a public release

None of these blocks the merge, and none is a code defect.

| # | Requirement |
| --- | --- |
| 1 | **A real release keystore.** Every APK so far is signed with the **debug key** and must not be distributed. |
| 2 | **A decision on live data.** Builds currently ship the bundled snapshot. Supplying `RAWNQ_SUPABASE_URL` / `RAWNQ_SUPABASE_ANON_KEY` switches to live — but that key belongs to the BringUs platform, so **ask the platform operator before shipping a build that carries it**. |
| 3 | **Exercise the live-API path once**, on a device. No build has yet run against the real storefront. |
| 4 | **Build and test on iOS**, if iOS is in scope. |
| 5 | **Privacy policy and terms.** Both are empty on the live tenant; app stores require a privacy policy. |
| 6 | **Confirm WhatsApp ordering with the shop** — that `+970593208117` is the right destination and the message format suits how they work. |
| 7 | Store listing assets, age rating, and a data-safety declaration. |

## Contributing

Work happens on feature branches off the default branch:

```bash
git checkout -b feature/<short-description>
```

Before opening a pull request:

```bash
dart format lib test && flutter analyze && flutter test
```

Never commit: `.env` files with real values, keystores (`*.jks`, `*.keystore`),
`key.properties`, `google-services.json`, provisioning profiles, or generated
localisations. All are covered by `.gitignore`.
