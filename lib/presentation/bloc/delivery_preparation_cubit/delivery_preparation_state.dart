part of 'delivery_preparation_cubit.dart';

enum DeliveryPreparationStatus { initial, loading, ready, empty, failure }

class DeliveryPreparationState extends Equatable {
  const DeliveryPreparationState({
    this.status = DeliveryPreparationStatus.initial,
    this.businessLocationId = '',
    this.rows = const [],
    this.prepMinutesByRow = const {},
    this.editingMinutesByRow = const {},
    this.pendingRows = const {},
    this.editingRowId,
    this.errorMessage = '',
    this.transientMessage = '',
  });

  final DeliveryPreparationStatus status;
  final String businessLocationId;
  final List<DeliveryMethodTableRow> rows;
  final Map<String, int> prepMinutesByRow;
  final Map<String, int> editingMinutesByRow;
  final Map<String, bool> pendingRows;
  final String? editingRowId;
  final String errorMessage;
  final String transientMessage;

  DeliveryPreparationState copyWith({
    DeliveryPreparationStatus? status,
    String? businessLocationId,
    List<DeliveryMethodTableRow>? rows,
    Map<String, int>? prepMinutesByRow,
    Map<String, int>? editingMinutesByRow,
    Map<String, bool>? pendingRows,
    Object? editingRowId = _deliveryPreparationSentinel,
    String? errorMessage,
    String? transientMessage,
    bool clearErrorMessage = false,
    bool clearTransientMessage = false,
    bool clearData = false,
  }) {
    return DeliveryPreparationState(
      status: status ?? this.status,
      businessLocationId: businessLocationId ?? this.businessLocationId,
      rows: clearData ? const [] : rows ?? this.rows,
      prepMinutesByRow: clearData
          ? const {}
          : prepMinutesByRow ?? this.prepMinutesByRow,
      editingMinutesByRow: clearData
          ? const {}
          : editingMinutesByRow ?? this.editingMinutesByRow,
      pendingRows: clearData ? const {} : pendingRows ?? this.pendingRows,
      editingRowId: identical(editingRowId, _deliveryPreparationSentinel)
          ? this.editingRowId
          : editingRowId as String?,
      errorMessage: clearErrorMessage ? '' : errorMessage ?? this.errorMessage,
      transientMessage: clearTransientMessage
          ? ''
          : transientMessage ?? this.transientMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    businessLocationId,
    rows,
    prepMinutesByRow,
    editingMinutesByRow,
    pendingRows,
    editingRowId,
    errorMessage,
    transientMessage,
  ];
}

const Object _deliveryPreparationSentinel = Object();
