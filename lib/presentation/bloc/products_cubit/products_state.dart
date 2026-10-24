part of 'products_cubit.dart';

enum ProductsStatus { initial, loading, ready, empty, failure }

class ProductsState extends Equatable {
  const ProductsState({
    this.status = ProductsStatus.initial,
    this.businessLocationId = '',
    this.rows = const [],
    this.searchQuery = '',
    this.errorMessage = '',
    this.transientMessage = '',
    this.savingByProductId = const {},
    this.expandedProductIds = const {},
    this.optionsByProductId = const {},
    this.variantsByProductId = const {},
    this.loadingOptionsByProductId = const {},
    this.savingByChoiceId = const {},
    this.savingByVariantId = const {},
  });

  final ProductsStatus status;
  final String businessLocationId;
  final List<ProductTableRow> rows;
  final String searchQuery;
  final String errorMessage;
  final String transientMessage;
  final Map<String, bool> savingByProductId;
  final Set<String> expandedProductIds;
  final Map<String, List<ProductOptionRow>> optionsByProductId;
  final Map<String, List<ProductVariantRow>> variantsByProductId;
  final Map<String, bool> loadingOptionsByProductId;
  final Map<String, bool> savingByChoiceId;
  final Map<String, bool> savingByVariantId;
  List<ProductTableRow> get visibleRows {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return rows;

    return rows
        .where((row) {
          return row.name.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  ProductsState copyWith({
    ProductsStatus? status,
    String? businessLocationId,
    List<ProductTableRow>? rows,
    String? searchQuery,
    String? errorMessage,
    String? transientMessage,
    Map<String, bool>? savingByProductId,
    Set<String>? expandedProductIds,
    Map<String, List<ProductOptionRow>>? optionsByProductId,
    Map<String, List<ProductVariantRow>>? variantsByProductId,
    Map<String, bool>? loadingOptionsByProductId,
    Map<String, bool>? savingByChoiceId,
    Map<String, bool>? savingByVariantId,
    bool clearErrorMessage = false,
    bool clearTransientMessage = false,
    bool clearData = false,
  }) {
    return ProductsState(
      status: status ?? this.status,
      businessLocationId: businessLocationId ?? this.businessLocationId,
      rows: clearData ? const [] : rows ?? this.rows,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearErrorMessage ? '' : errorMessage ?? this.errorMessage,
      transientMessage: clearTransientMessage
          ? ''
          : transientMessage ?? this.transientMessage,
      savingByProductId: savingByProductId ?? this.savingByProductId,
      expandedProductIds: clearData
          ? const {}
          : expandedProductIds ?? this.expandedProductIds,
      optionsByProductId: clearData
          ? const {}
          : optionsByProductId ?? this.optionsByProductId,
      variantsByProductId: clearData
          ? const {}
          : variantsByProductId ?? this.variantsByProductId,
      loadingOptionsByProductId: clearData
          ? const {}
          : loadingOptionsByProductId ?? this.loadingOptionsByProductId,
      savingByChoiceId: clearData
          ? const {}
          : savingByChoiceId ?? this.savingByChoiceId,
      savingByVariantId: clearData
          ? const {}
          : savingByVariantId ?? this.savingByVariantId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    businessLocationId,
    rows,
    searchQuery,
    errorMessage,
    transientMessage,
    savingByProductId,
    expandedProductIds,
    optionsByProductId,
    variantsByProductId,
    loadingOptionsByProductId,
    savingByChoiceId,
    savingByVariantId,
  ];
}
