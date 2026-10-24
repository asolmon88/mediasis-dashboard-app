import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses location visibility from a product variant response', () {
    final variant = ProductVariantRow.fromMap({
      'product_variant_id': 'variant-1',
      'name': 'Grande',
      'price': 4500,
      'visible_at_location': false,
    });

    expect(variant.productVariantId, 'variant-1');
    expect(variant.name, 'Grande');
    expect(variant.price, 4500);
    expect(variant.visibleAtLocation, isFalse);
  });

  test('loads variants when the product management panel expands', () async {
    final service = _FakeProductsService();
    final cubit = ProductsCubit(productsService: service);

    await cubit.loadProducts(businessLocationId: 'location-1');
    await cubit.toggleOptionsPanel('product-1');

    expect(cubit.state.expandedProductIds, contains('product-1'));
    expect(cubit.state.variantsByProductId['product-1'], hasLength(2));
    expect(service.fetchVariantsCalls, 1);

    await cubit.close();
  });

  test(
    'updates a variant visibility optimistically and keeps success',
    () async {
      final service = _FakeProductsService();
      final cubit = ProductsCubit(productsService: service);

      await cubit.loadProducts(businessLocationId: 'location-1');
      await cubit.toggleOptionsPanel('product-1');
      await cubit.toggleVariantVisibility(
        productId: 'product-1',
        variantId: 'variant-1',
        nextVisible: false,
      );

      final variant = cubit.state.variantsByProductId['product-1']!.first;
      expect(variant.visibleAtLocation, isFalse);
      expect(cubit.state.rows.single.visibility, isTrue);

      await cubit.close();
    },
  );

  test('hides the parent while retaining the last available variant', () async {
    final service = _FakeProductsService(productHidden: true);
    final cubit = ProductsCubit(productsService: service);

    await cubit.loadProducts(businessLocationId: 'location-1');
    await cubit.toggleOptionsPanel('product-1');
    await cubit.toggleVariantVisibility(
      productId: 'product-1',
      variantId: 'variant-1',
      nextVisible: false,
    );

    final variant = cubit.state.variantsByProductId['product-1']!.first;
    expect(variant.visibleAtLocation, isTrue);
    expect(cubit.state.rows.single.visibility, isFalse);
    expect(cubit.state.transientMessage, contains('oculto el producto'));

    await cubit.close();
  });
}

class _FakeProductsService extends SupabaseProductsService {
  _FakeProductsService({this.productHidden = false});

  final bool productHidden;
  int fetchVariantsCalls = 0;

  @override
  Future<List<ProductTableRow>> fetchProductsTable({
    required String businessLocationId,
  }) async {
    return const [
      ProductTableRow(
        productId: 'product-1',
        name: 'Hamburguesa',
        price: 4000,
        categories: [],
        images: [],
        visibility: true,
      ),
    ];
  }

  @override
  Future<List<ProductVariantRow>> fetchProductVariants({
    required String productId,
    required String businessLocationId,
  }) async {
    fetchVariantsCalls++;
    return const [
      ProductVariantRow(
        productVariantId: 'variant-1',
        name: 'Regular',
        price: 4000,
        visibleAtLocation: true,
      ),
      ProductVariantRow(
        productVariantId: 'variant-2',
        name: 'Grande',
        price: 5000,
        visibleAtLocation: true,
      ),
    ];
  }

  @override
  Future<List<ProductOptionRow>> fetchProductOptions({
    required String productId,
    required String businessLocationId,
  }) async {
    return const [];
  }

  @override
  Future<ProductVariantVisibilityResult> setVariantVisibility({
    required String productVariantId,
    required String businessLocationId,
    required bool visible,
  }) async {
    return ProductVariantVisibilityResult(
      success: true,
      productHidden: productHidden,
      visibleAtLocation: productHidden ? true : visible,
    );
  }
}
