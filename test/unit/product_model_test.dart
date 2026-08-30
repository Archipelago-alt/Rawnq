import 'package:flutter_test/flutter_test.dart';
import 'package:rawnq/shared/models/product.dart';

import '../support/fixtures.dart';

void main() {
  group('Product.fromJson', () {
    test(
      'reads images from the flat image_url_N columns the API actually uses',
      () {
        final product = Product.fromJson(const <String, dynamic>{
          'id': 'p1',
          'name': 'قميص',
          'price': 80,
          'images': null,
          'image_url_1': 'https://cdn/1.webp',
          'image_url_2': 'https://cdn/2.webp',
          'image_url_5': 'https://cdn/5.webp',
        });

        expect(product.images, <String>[
          'https://cdn/1.webp',
          'https://cdn/2.webp',
          'https://cdn/5.webp',
        ]);
        expect(product.primaryImage, 'https://cdn/1.webp');
      },
    );

    test('prefers the images array when the API supplies one', () {
      final product = Product.fromJson(const <String, dynamic>{
        'id': 'p1',
        'name': 'قميص',
        'price': 80,
        'images': <String>['https://cdn/a.webp'],
        'image_url_1': 'https://cdn/ignored.webp',
      });

      expect(product.images, <String>['https://cdn/a.webp']);
    });

    test('falls back to price_1 when price is absent', () {
      final product = Product.fromJson(const <String, dynamic>{
        'id': 'p1',
        'name': 'قميص',
        'price_1': 70,
      });

      expect(product.price, 70);
    });

    test('parses variant options out of the attributes map', () {
      final product = Product.fromJson(
        const <String, dynamic>{'id': 'p1', 'name': 'بجامة', 'price_1': 100},
        variants: <ProductVariant>[
          ProductVariant.fromJson(const <String, dynamic>{
            'id': 'v1',
            'product_id': 'p1',
            'variant_name': 'اسود-لارج',
            'price_1': 100,
            'stock_quantity': 2,
            'attributes': <String, dynamic>{
              'color': 'اسود',
              'color_hex': '#11121A',
              'size': 'L',
              'material': 'قطن',
            },
          }),
        ],
      );

      final variant = product.variants.single;
      expect(variant.color, 'اسود');
      expect(variant.size, 'L');
      expect(variant.material, 'قطن');
      expect(variant.swatch?.toARGB32(), 0xFF11121A);
      expect(variant.inStock, isTrue);
    });

    test('treats a malformed colour hex as no swatch rather than crashing', () {
      const variant = ProductVariant(
        id: 'v',
        productId: 'p',
        name: 'x',
        price: 10,
        stock: 1,
        colorHex: 'not-a-colour',
      );

      expect(variant.swatch, isNull);
    });
  });

  group('availability', () {
    test('a variant product is available when any variant has stock', () {
      expect(Fixtures.pyjamaWithSizes.inStock, isTrue);
    });

    test('a variant product is unavailable when every variant is empty', () {
      const product = Product(
        id: 'p',
        name: 'x',
        price: 10,
        stock: 99, // product-level stock must not mask empty variants
        variants: <ProductVariant>[
          ProductVariant(
            id: 'v',
            productId: 'p',
            name: 'v',
            price: 10,
            stock: 0,
          ),
        ],
      );

      expect(product.inStock, isFalse);
    });

    test('a product without variants falls back to its own stock', () {
      expect(Fixtures.shirtNoVariants.inStock, isTrue);
      expect(Fixtures.soldOut.inStock, isFalse);
    });
  });

  group('options', () {
    test('colour options are de-duplicated across sizes', () {
      final colors = Fixtures.pyjamaWithSizes.colorOptions
          .map((variant) => variant.color)
          .toList();

      expect(colors, <String>['خمري غامق', 'Sand beige']);
    });

    test('sizes are scoped to the chosen colour', () {
      expect(Fixtures.pyjamaWithSizes.sizesFor('خمري غامق'), <String>[
        'M',
        'L',
      ]);
      expect(Fixtures.pyjamaWithSizes.sizesFor('Sand beige'), <String>['XL']);
    });

    test('a colour-only product reports no sizes', () {
      expect(Fixtures.lingerieColorsOnly.hasSizes, isFalse);
      expect(Fixtures.lingerieColorsOnly.sizesFor('اسود'), isEmpty);
    });

    test('findVariant resolves a colour and size pair', () {
      final variant = Fixtures.pyjamaWithSizes.findVariant(
        color: 'خمري غامق',
        size: 'L',
      );

      expect(variant?.id, 'v-l');
    });

    test('findVariant returns null for a combination that does not exist', () {
      final variant = Fixtures.pyjamaWithSizes.findVariant(
        color: 'Sand beige',
        size: 'M',
      );

      expect(variant, isNull);
    });
  });

  group('pricing', () {
    test('display price is the cheapest variant when variants exist', () {
      const product = Product(
        id: 'p',
        name: 'x',
        price: 200,
        variants: <ProductVariant>[
          ProductVariant(
            id: 'a',
            productId: 'p',
            name: 'a',
            price: 120,
            stock: 1,
          ),
          ProductVariant(
            id: 'b',
            productId: 'p',
            name: 'b',
            price: 90,
            stock: 1,
          ),
        ],
      );

      expect(product.displayPrice, 90);
    });

    test('no sale badge when the shop is not discounting', () {
      // Every live RAWNQ product is in this state today.
      expect(Fixtures.shirtNoVariants.isOnSale, isFalse);
      expect(Fixtures.shirtNoVariants.discountBadge, isNull);
    });

    test('compare_at_price drives the sale badge', () {
      const product = Product(
        id: 'p',
        name: 'x',
        price: 80,
        compareAtPrice: 100,
      );

      expect(product.isOnSale, isTrue);
      expect(product.effectiveOriginalPrice, 100);
      expect(product.discountBadge, 20);
    });

    test('a percentage discount reconstructs the original price', () {
      const product = Product(
        id: 'p',
        name: 'x',
        price: 75,
        discountPercentage: 25,
        showDiscount: true,
      );

      expect(product.effectiveOriginalPrice, closeTo(100, 0.001));
      expect(product.discountBadge, 25);
    });

    test(
      'a percentage is ignored while the shop keeps show_discount false',
      () {
        const product = Product(
          id: 'p',
          name: 'x',
          price: 75,
          discountPercentage: 25,
        );

        expect(product.isOnSale, isFalse);
      },
    );
  });

  group('gallery', () {
    test('the selected variant photo is promoted to the front', () {
      const product = Product(
        id: 'p',
        name: 'x',
        price: 10,
        images: <String>['a.webp', 'b.webp'],
      );
      const variant = ProductVariant(
        id: 'v',
        productId: 'p',
        name: 'v',
        price: 10,
        stock: 1,
        imageUrl: 'b.webp',
      );

      expect(product.galleryFor(variant), <String>['b.webp', 'a.webp']);
    });

    test('gallery is unchanged when the variant has no photo of its own', () {
      const product = Product(
        id: 'p',
        name: 'x',
        price: 10,
        images: <String>['a.webp', 'b.webp'],
      );

      expect(product.galleryFor(null), <String>['a.webp', 'b.webp']);
    });
  });

  test('the new label drives the جديد badge', () {
    expect(Fixtures.pyjamaWithSizes.isNew, isTrue);
    expect(Fixtures.shirtNoVariants.isNew, isFalse);
  });
}
