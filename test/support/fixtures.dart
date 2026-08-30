import 'package:rawnq/shared/models/catalog.dart';
import 'package:rawnq/shared/models/category.dart';
import 'package:rawnq/shared/models/checkout_options.dart';
import 'package:rawnq/shared/models/product.dart';
import 'package:rawnq/shared/models/store_info.dart';

/// Test data shaped exactly like the live storefront's, including its quirks:
/// prices carried in the tier-1 column, variants whose options live in a JSON
/// `attributes` map, and colours that mix Arabic and English names.
class Fixtures {
  const Fixtures._();

  static const StoreInfo store = StoreInfo(
    id: 'tenant-1',
    slug: 'rawnqgaza',
    label: 'رونق | RAWNQ',
    brandColor: '#7c3918',
    currency: 'ILS',
    slogan: 'لأنكِ تستحقين الأجمل',
    country: 'Palestine',
    whatsapp: '+970593208117',
    instagram: 'https://www.instagram.com/rawnqgaza/',
  );

  static const ProductCategory pyjamas = ProductCategory(
    id: 'cat-pyjamas',
    name: 'بجامات',
    sortOrder: 3,
  );

  static const ProductCategory shirts = ProductCategory(
    id: 'cat-shirts',
    name: 'قُمْصَان',
    sortOrder: 0,
  );

  static const Brand lubna = Brand(id: 'brand-lubna', name: 'لبنى');

  /// A product with colours *and* sizes — both options are mandatory.
  static final Product pyjamaWithSizes = Product(
    id: 'p-pyjama',
    name: 'بجامة منزلية اية موضة بنقشة أوراق',
    description: 'بجامة قطنية مريحة بتصميم عصري.',
    price: 100,
    categoryId: pyjamas.id,
    brandId: lubna.id,
    labels: const <String>['new'],
    stock: 4,
    images: const <String>['https://cdn.example/pyjama-1.webp'],
    sortOrder: 1,
    variants: const <ProductVariant>[
      ProductVariant(
        id: 'v-m',
        productId: 'p-pyjama',
        name: 'خمري غامق-ميديم',
        price: 100,
        stock: 1,
        color: 'خمري غامق',
        colorHex: '#4B3438',
        size: 'M',
        material: 'قطن',
      ),
      ProductVariant(
        id: 'v-l',
        productId: 'p-pyjama',
        name: 'خمري غامق-لارج',
        price: 100,
        stock: 2,
        color: 'خمري غامق',
        colorHex: '#4B3438',
        size: 'L',
        material: 'قطن',
      ),
      ProductVariant(
        id: 'v-beige-xl',
        productId: 'p-pyjama',
        name: 'بيج رملي-اكس لارج',
        price: 100,
        stock: 0,
        color: 'Sand beige',
        colorHex: '#B8AA9B',
        size: 'XL',
        material: 'قطن',
      ),
    ],
  );

  /// A product with colours but no sizes — only the colour is mandatory.
  static const Product lingerieColorsOnly = Product(
    id: 'p-lingerie',
    name: 'طقم لانجري صيفي فاخر',
    price: 40,
    categoryId: 'cat-lingerie',
    stock: 8,
    images: <String>['https://cdn.example/lingerie-1.webp'],
    sortOrder: 2,
    variants: <ProductVariant>[
      ProductVariant(
        id: 'v-black',
        productId: 'p-lingerie',
        name: 'اسود',
        price: 40,
        stock: 1,
        color: 'اسود',
        colorHex: '#11121A',
        material: 'قطن',
      ),
      ProductVariant(
        id: 'v-pink',
        productId: 'p-lingerie',
        name: 'زهري',
        price: 40,
        stock: 0,
        color: 'زهري',
        colorHex: '#fdbefe',
        material: 'قطن',
      ),
    ],
  );

  /// A product with no variants at all — buyable directly.
  static final Product shirtNoVariants = Product(
    id: 'p-shirt',
    name: 'قميص كلاسيكي',
    price: 80,
    categoryId: shirts.id,
    stock: 3,
    images: const <String>['https://cdn.example/shirt-1.webp'],
    sortOrder: 0,
  );

  /// Sold out everywhere.
  static const Product soldOut = Product(
    id: 'p-soldout',
    name: 'فستان سهرة',
    price: 90,
    categoryId: 'cat-dresses',
    stock: 0,
    images: <String>['https://cdn.example/dress-1.webp'],
    sortOrder: 4,
  );

  static const DeliveryLocation gaza = DeliveryLocation(
    id: 'loc-gaza',
    name: 'غزة',
    price: 0,
  );

  static const StorePaymentMethod cashOnDelivery = StorePaymentMethod(
    id: 'pay-cod',
    name: 'الدفع عند الاستلام',
    type: 'cod',
  );

  static Catalog catalog({bool isLiveData = true}) => Catalog(
    store: store,
    categories: const <ProductCategory>[shirts, pyjamas],
    brands: const <Brand>[lubna],
    products: <Product>[
      shirtNoVariants,
      pyjamaWithSizes,
      lingerieColorsOnly,
      soldOut,
    ],
    deliveryLocations: const <DeliveryLocation>[gaza],
    paymentMethods: const <StorePaymentMethod>[cashOnDelivery],
    isLiveData: isLiveData,
  );
}
