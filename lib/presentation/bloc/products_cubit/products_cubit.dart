import 'dart:async';

import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit({SupabaseProductsService? productsService})
    : _productsService = productsService ?? SupabaseProductsService(),
      super(const ProductsState());

  final SupabaseProductsService _productsService;

  Future<void> loadProducts({
    required String businessLocationId,
    bool force = false,
  }) async {
    if (businessLocationId.isEmpty) {
      emit(
        state.copyWith(
          status: ProductsStatus.failure,
          businessLocationId: '',
          errorMessage: 'No hay una ubicación activa.',
          clearData: true,
        ),
      );
      return;
    }

    final isSameLocation = state.businessLocationId == businessLocationId;
    if (!force &&
        isSameLocation &&
        (state.status == ProductsStatus.ready ||
            state.status == ProductsStatus.empty ||
            state.status == ProductsStatus.loading)) {
      return;
    }

    emit(
      state.copyWith(
        status: ProductsStatus.loading,
        businessLocationId: businessLocationId,
        clearErrorMessage: true,
        clearData: !isSameLocation,
      ),
    );

    await _fetchRows(businessLocationId);
  }

  Future<void> refresh() async {
    if (state.businessLocationId.isEmpty) return;
    emit(
      state.copyWith(status: ProductsStatus.loading, clearErrorMessage: true),
    );
    await _fetchRows(state.businessLocationId);
  }

  void setSearchQuery(String value) {
    emit(state.copyWith(searchQuery: value));
  }

  Future<OrderActionResult> toggleVisibility({
    required String businessLocationId,
    required String productId,
    required bool nextVisibility,
  }) async {
    if (state.savingByProductId[productId] == true) {
      return const OrderActionResult(success: true);
    }

    final currentRow = state.rows
        .where((row) => row.productId == productId)
        .firstOrNull;
    if (currentRow == null || currentRow.visibility == nextVisibility) {
      return const OrderActionResult(success: true);
    }
    if (businessLocationId.isEmpty) {
      return const OrderActionResult(
        success: false,
        message: 'No hay una ubicación activa para actualizar este producto.',
      );
    }

    emit(
      state.copyWith(
        rows: state.rows
            .map(
              (row) => row.productId == productId
                  ? row.copyWith(visibility: nextVisibility)
                  : row,
            )
            .toList(growable: false),
        savingByProductId: {...state.savingByProductId, productId: true},
        clearTransientMessage: true,
      ),
    );

    try {
      final result = await _productsService.updateProductVisibility(
        businessLocationId: businessLocationId,
        productId: productId,
        visibility: nextVisibility,
      );
      if (!result.success) {
        throw StateError(
          result.message ??
              'No se pudo actualizar la visibilidad del producto en esta ubicación.',
        );
      }

      final nextSaving = {...state.savingByProductId}..remove(productId);
      emit(state.copyWith(savingByProductId: nextSaving));
      return const OrderActionResult(success: true);
    } catch (error) {
      final revertedRows = state.rows
          .map(
            (row) => row.productId == productId
                ? row.copyWith(visibility: currentRow.visibility)
                : row,
          )
          .toList(growable: false);
      final nextSaving = {...state.savingByProductId}..remove(productId);
      emit(
        state.copyWith(
          rows: revertedRows,
          savingByProductId: nextSaving,
          transientMessage:
              '$error'.replaceFirst('Bad state: ', '').trim().isEmpty
              ? 'No se pudo actualizar la visibilidad del producto en esta ubicación.'
              : '$error'.replaceFirst('Bad state: ', '').trim(),
        ),
      );
      return OrderActionResult(
        success: false,
        message: '$error'.replaceFirst('Bad state: ', '').trim().isEmpty
            ? 'No se pudo actualizar la visibilidad del producto en esta ubicación.'
            : '$error'.replaceFirst('Bad state: ', '').trim(),
      );
    }
  }

  Future<void> toggleOptionsPanel(String productId) async {
    if (state.expandedProductIds.contains(productId)) {
      emit(
        state.copyWith(
          expandedProductIds: {...state.expandedProductIds}..remove(productId),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        expandedProductIds: {...state.expandedProductIds, productId},
        loadingOptionsByProductId: {
          ...state.loadingOptionsByProductId,
          productId: true,
        },
      ),
    );

    try {
      final variants = await _productsService.fetchProductVariants(
        productId: productId,
        businessLocationId: state.businessLocationId,
      );
      final options = await _productsService.fetchProductOptions(
        productId: productId,
        businessLocationId: state.businessLocationId,
      );
      final nextLoading = {...state.loadingOptionsByProductId}
        ..remove(productId);
      emit(
        state.copyWith(
          optionsByProductId: {...state.optionsByProductId, productId: options},
          variantsByProductId: {
            ...state.variantsByProductId,
            productId: variants,
          },
          loadingOptionsByProductId: nextLoading,
        ),
      );
    } catch (error) {
      final nextLoading = {...state.loadingOptionsByProductId}
        ..remove(productId);
      emit(
        state.copyWith(
          loadingOptionsByProductId: nextLoading,
          transientMessage:
              '$error'.replaceFirst('Bad state: ', '').trim().isEmpty
              ? 'No se pudieron cargar los detalles del producto.'
              : '$error'.replaceFirst('Bad state: ', '').trim(),
        ),
      );
    }
  }

  Future<void> toggleChoiceVisibility({
    required String choiceId,
    required String productId,
    required String optionId,
    required bool nextVisible,
  }) async {
    if (state.savingByChoiceId[choiceId] == true) return;

    final currentOptions = state.optionsByProductId[productId];
    if (currentOptions == null) return;

    // Find the current choice to get its original value for revert
    ProductOptionChoiceRow? currentChoice;
    outer:
    for (final option in currentOptions) {
      for (final choice in option.choices) {
        if (choice.productOptionChoiceId == choiceId) {
          currentChoice = choice;
          break outer;
        }
      }
    }
    if (currentChoice == null ||
        currentChoice.visibleAtLocation == nextVisible) {
      return;
    }

    // Optimistic update: flip visibleAtLocation on the matching choice
    final optimisticOptions = currentOptions
        .map((option) {
          if (option.productOptionId != optionId) return option;
          return option.copyWith(
            choices: option.choices
                .map(
                  (c) => c.productOptionChoiceId == choiceId
                      ? c.copyWith(visibleAtLocation: nextVisible)
                      : c,
                )
                .toList(growable: false),
          );
        })
        .toList(growable: false);

    emit(
      state.copyWith(
        optionsByProductId: {
          ...state.optionsByProductId,
          productId: optimisticOptions,
        },
        savingByChoiceId: {...state.savingByChoiceId, choiceId: true},
        clearTransientMessage: true,
      ),
    );

    try {
      final result = await _productsService.setChoiceVisibility(
        productOptionChoiceId: choiceId,
        businessLocationId: state.businessLocationId,
        visible: nextVisible,
      );
      if (!result.success) {
        throw StateError(
          result.message ??
              'No se pudo actualizar la visibilidad de la eleccion.',
        );
      }
      final nextSaving = {...state.savingByChoiceId}..remove(choiceId);
      emit(state.copyWith(savingByChoiceId: nextSaving));
    } catch (error) {
      // Revert the choice back to its original value
      final revertedOptions = (state.optionsByProductId[productId] ?? [])
          .map((option) {
            if (option.productOptionId != optionId) return option;
            return option.copyWith(
              choices: option.choices
                  .map(
                    (c) => c.productOptionChoiceId == choiceId
                        ? c.copyWith(
                            visibleAtLocation: currentChoice!.visibleAtLocation,
                          )
                        : c,
                  )
                  .toList(growable: false),
            );
          })
          .toList(growable: false);
      final nextSaving = {...state.savingByChoiceId}..remove(choiceId);
      final msg = '$error'.replaceFirst('Bad state: ', '').trim();
      emit(
        state.copyWith(
          optionsByProductId: {
            ...state.optionsByProductId,
            productId: revertedOptions,
          },
          savingByChoiceId: nextSaving,
          transientMessage: msg.isEmpty
              ? 'No se pudo actualizar la visibilidad de la eleccion.'
              : msg,
        ),
      );
    }
  }

  Future<void> toggleVariantVisibility({
    required String productId,
    required String variantId,
    required bool nextVisible,
  }) async {
    if (state.savingByVariantId[variantId] == true) return;

    final currentVariants = state.variantsByProductId[productId];
    if (currentVariants == null) return;
    final currentVariant = currentVariants
        .where((variant) => variant.productVariantId == variantId)
        .firstOrNull;
    if (currentVariant == null ||
        currentVariant.visibleAtLocation == nextVisible) {
      return;
    }

    final optimisticVariants = currentVariants
        .map(
          (variant) => variant.productVariantId == variantId
              ? variant.copyWith(visibleAtLocation: nextVisible)
              : variant,
        )
        .toList(growable: false);
    emit(
      state.copyWith(
        variantsByProductId: {
          ...state.variantsByProductId,
          productId: optimisticVariants,
        },
        savingByVariantId: {...state.savingByVariantId, variantId: true},
        clearTransientMessage: true,
      ),
    );

    try {
      final result = await _productsService.setVariantVisibility(
        productVariantId: variantId,
        businessLocationId: state.businessLocationId,
        visible: nextVisible,
      );
      if (!result.success) {
        throw StateError(
          result.message ??
              'No se pudo actualizar la visibilidad de la variante.',
        );
      }

      final nextSaving = {...state.savingByVariantId}..remove(variantId);
      if (result.productHidden) {
        final restoredVariants = (state.variantsByProductId[productId] ?? [])
            .map(
              (variant) => variant.productVariantId == variantId
                  ? variant.copyWith(
                      visibleAtLocation:
                          result.visibleAtLocation ??
                          currentVariant.visibleAtLocation,
                    )
                  : variant,
            )
            .toList(growable: false);
        emit(
          state.copyWith(
            rows: state.rows
                .map(
                  (row) => row.productId == productId
                      ? row.copyWith(visibility: false)
                      : row,
                )
                .toList(growable: false),
            variantsByProductId: {
              ...state.variantsByProductId,
              productId: restoredVariants,
            },
            savingByVariantId: nextSaving,
            transientMessage:
                'Se oculto el producto porque debe conservar al menos una variante disponible.',
          ),
        );
        return;
      }

      final authoritativeVariants = (state.variantsByProductId[productId] ?? [])
          .map(
            (variant) => variant.productVariantId == variantId
                ? variant.copyWith(
                    visibleAtLocation: result.visibleAtLocation ?? nextVisible,
                  )
                : variant,
          )
          .toList(growable: false);
      emit(
        state.copyWith(
          variantsByProductId: {
            ...state.variantsByProductId,
            productId: authoritativeVariants,
          },
          savingByVariantId: nextSaving,
        ),
      );
    } catch (error) {
      final revertedVariants = (state.variantsByProductId[productId] ?? [])
          .map(
            (variant) => variant.productVariantId == variantId
                ? variant.copyWith(
                    visibleAtLocation: currentVariant.visibleAtLocation,
                  )
                : variant,
          )
          .toList(growable: false);
      final nextSaving = {...state.savingByVariantId}..remove(variantId);
      final message = '$error'.replaceFirst('Bad state: ', '').trim();
      emit(
        state.copyWith(
          variantsByProductId: {
            ...state.variantsByProductId,
            productId: revertedVariants,
          },
          savingByVariantId: nextSaving,
          transientMessage: message.isEmpty
              ? 'No se pudo actualizar la visibilidad de la variante.'
              : message,
        ),
      );
    }
  }

  void clearTransientMessage() {
    if (state.transientMessage.isEmpty) return;
    emit(state.copyWith(clearTransientMessage: true));
  }

  void reset() {
    emit(const ProductsState());
  }

  Future<void> _fetchRows(String businessLocationId) async {
    try {
      final rows = await _productsService.fetchProductsTable(
        businessLocationId: businessLocationId,
      );
      emit(
        state.copyWith(
          status: rows.isEmpty ? ProductsStatus.empty : ProductsStatus.ready,
          businessLocationId: businessLocationId,
          rows: rows,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProductsStatus.failure,
          businessLocationId: businessLocationId,
          errorMessage: '$error'.replaceFirst('Bad state: ', '').trim().isEmpty
              ? 'No se pudieron cargar los productos.'
              : '$error'.replaceFirst('Bad state: ', '').trim(),
          clearData: true,
        ),
      );
    }
  }
}
