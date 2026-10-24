part of 'orders_table_cubit.dart';

enum OrdersTableStatus { initial, loading, ready, empty, failure }

enum OrdersTableSortBy {
  createdAt('created_at'),
  total('total');

  const OrdersTableSortBy(this.value);

  final String value;
}

enum OrdersTableSortDirection {
  asc('asc'),
  desc('desc');

  const OrdersTableSortDirection(this.value);

  final String value;
}

class OrdersTableState extends Equatable {
  const OrdersTableState({
    this.status = OrdersTableStatus.initial,
    this.businessLocationId = '',
    this.rows = const [],
    this.paymentStatusFilters = const ['paid'],
    this.searchQuery = '',
    this.errorMessage = '',
    this.transientMessage = '',
    this.page = 1,
    this.limit = 50,
    this.hasMore = false,
    this.sortBy = OrdersTableSortBy.createdAt,
    this.sortDirection = OrdersTableSortDirection.desc,
    this.savingByOrderId = const {},
  });

  final OrdersTableStatus status;
  final String businessLocationId;
  final List<OrdersTableRow> rows;
  final List<String> paymentStatusFilters;
  final String searchQuery;
  final String errorMessage;
  final String transientMessage;
  final int page;
  final int limit;
  final bool hasMore;
  final OrdersTableSortBy sortBy;
  final OrdersTableSortDirection sortDirection;
  final Map<String, bool> savingByOrderId;

  int get offset => (page - 1) * limit;

  List<OrdersTableRow> get visibleRows {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return rows;

    return rows
        .where((row) {
          return row.orderId.toLowerCase().contains(query) ||
              row.customerName.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  OrdersTableState copyWith({
    OrdersTableStatus? status,
    String? businessLocationId,
    List<OrdersTableRow>? rows,
    List<String>? paymentStatusFilters,
    String? searchQuery,
    String? errorMessage,
    String? transientMessage,
    int? page,
    int? limit,
    bool? hasMore,
    OrdersTableSortBy? sortBy,
    OrdersTableSortDirection? sortDirection,
    Map<String, bool>? savingByOrderId,
    bool clearErrorMessage = false,
    bool clearTransientMessage = false,
    bool clearData = false,
  }) {
    return OrdersTableState(
      status: status ?? this.status,
      businessLocationId: businessLocationId ?? this.businessLocationId,
      rows: clearData ? const [] : rows ?? this.rows,
      paymentStatusFilters: paymentStatusFilters ?? this.paymentStatusFilters,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearErrorMessage ? '' : errorMessage ?? this.errorMessage,
      transientMessage: clearTransientMessage
          ? ''
          : transientMessage ?? this.transientMessage,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      savingByOrderId: savingByOrderId ?? this.savingByOrderId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    businessLocationId,
    rows,
    paymentStatusFilters,
    searchQuery,
    errorMessage,
    transientMessage,
    page,
    limit,
    hasMore,
    sortBy,
    sortDirection,
    savingByOrderId,
  ];
}
