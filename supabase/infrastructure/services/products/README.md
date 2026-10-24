# Product Supabase code

This folder contains database code used by Flutter's
`lib/infrastructure/services/supabase_products_service.dart` and the Products
cubit/UI.

## Variant visibility

Apply `01_product_variant_visibility.sql` before deploying the related dashboard
API routes.

| Database object | Dashboard API | Flutter consumer |
| --- | --- | --- |
| `product_variant.visibility` | Both variant routes | `ProductVariantRow.visibleAtLocation` |
| `mediasis.get_product_variants_for_app(...)` | `GET /api/products/variants` | `SupabaseProductsService.fetchProductVariants(...)` |
| `mediasis.set_product_variant_visibility_at_location(...)` | `POST /api/products/variant-visibility` | `ProductsCubit.toggleVariantVisibility(...)` |
| `mediasis.show_product_at_location(...)` | `POST /api/products/product-visibility` | `ProductsCubit.toggleVisibility(...)` |
| `mediasis.hide_product_at_location(...)` | `POST /api/products/product-visibility` | `ProductsCubit.toggleVisibility(...)` |

The SQL intentionally excludes the default variant from variant controls. The
default variant remains the location visibility source for the parent product.

Customer-facing ordering and checkout RPCs must also honor
`product_variant.visibility` before variant hiding is enabled in production.
