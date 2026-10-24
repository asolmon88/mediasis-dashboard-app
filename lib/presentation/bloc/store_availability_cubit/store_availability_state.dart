part of 'store_availability_cubit.dart';

enum StoreAvailabilityStatus { initial, loading, ready, failure }

class StoreAvailabilityState extends Equatable {
  const StoreAvailabilityState({
    this.status = StoreAvailabilityStatus.initial,
    this.businessLocationId = '',
    this.isOpen = true,
    this.note = '',
    this.errorMessage = '',
    this.transientMessage = '',
    this.isSaving = false,
  });

  final StoreAvailabilityStatus status;
  final String businessLocationId;
  final bool isOpen;
  final String note;
  final String errorMessage;
  final String transientMessage;
  final bool isSaving;

  StoreAvailabilityState copyWith({
    StoreAvailabilityStatus? status,
    String? businessLocationId,
    bool? isOpen,
    String? note,
    String? errorMessage,
    String? transientMessage,
    bool? isSaving,
    bool clearErrorMessage = false,
    bool clearTransientMessage = false,
    bool clearSnapshot = false,
  }) {
    return StoreAvailabilityState(
      status: status ?? this.status,
      businessLocationId: businessLocationId ?? this.businessLocationId,
      isOpen: clearSnapshot ? true : isOpen ?? this.isOpen,
      note: clearSnapshot ? '' : note ?? this.note,
      errorMessage: clearErrorMessage ? '' : errorMessage ?? this.errorMessage,
      transientMessage: clearTransientMessage
          ? ''
          : transientMessage ?? this.transientMessage,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [
    status,
    businessLocationId,
    isOpen,
    note,
    errorMessage,
    transientMessage,
    isSaving,
  ];
}
