import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDiscountBreakdown {
  const OrderDiscountBreakdown({
    required this.code,
    required this.title,
    required this.endsAt,
    required this.startsAt,
    required this.appliesTo,
    required this.valueType,
    required this.discountId,
    required this.valueAmount,
    required this.locationScope,
    required this.discountAmount,
    required this.eligibleSubtotal,
    required this.orderTotalAfterDiscount,
    required this.orderTotalBeforeDiscount,
  });

  final String code;
  final String title;
  final String? endsAt;
  final String startsAt;
  final String appliesTo;
  final String valueType;
  final String discountId;
  final double valueAmount;
  final String locationScope;
  final double discountAmount;
  final double eligibleSubtotal;
  final double orderTotalAfterDiscount;
  final double orderTotalBeforeDiscount;

  factory OrderDiscountBreakdown.fromMap(Map<String, dynamic> map) {
    return OrderDiscountBreakdown(
      code: map['code'] as String? ?? '',
      title: map['title'] as String? ?? '',
      endsAt: map['ends_at'] as String?,
      startsAt: map['starts_at'] as String? ?? '',
      appliesTo: map['applies_to'] as String? ?? '',
      valueType: map['value_type'] as String? ?? '',
      discountId: map['discount_id'] as String? ?? '',
      valueAmount: _toDouble(map['value_amount']),
      locationScope: map['location_scope'] as String? ?? '',
      discountAmount: _toDouble(map['discount_amount']),
      eligibleSubtotal: _toDouble(map['eligible_subtotal']),
      orderTotalAfterDiscount: _toDouble(map['order_total_after_discount']),
      orderTotalBeforeDiscount: _toDouble(map['order_total_before_discount']),
    );
  }
}

class OrderRealtimeDeliveryMethod {
  const OrderRealtimeDeliveryMethod({
    required this.uid,
    required this.name,
    required this.requireCourier,
    required this.requireLocation,
  });

  final String uid;
  final String name;
  final bool requireCourier;
  final bool requireLocation;

  factory OrderRealtimeDeliveryMethod.fromMap(Map<String, dynamic> map) {
    return OrderRealtimeDeliveryMethod(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      requireCourier: map['require_courier'] as bool? ?? false,
      requireLocation: map['require_location'] as bool? ?? false,
    );
  }
}

class OrderRealtimeItem {
  const OrderRealtimeItem({
    required this.quantity,
    required this.totalPrice,
    required this.options,
    required this.productVariantName,
    this.image,
  });

  final int quantity;
  final double totalPrice;
  final dynamic options;
  final String productVariantName;
  final String? image;

  factory OrderRealtimeItem.fromMap(Map<String, dynamic> map) {
    return OrderRealtimeItem(
      quantity: _toInt(map['quantity']),
      totalPrice: _toDouble(map['total_price']),
      options: map['options'],
      productVariantName: map['product_variant_name'] as String? ?? '',
      image: map['image'] as String?,
    );
  }
}

class OrderRealtimeClient {
  const OrderRealtimeClient({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
  });

  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? email;

  factory OrderRealtimeClient.fromMap(Map<String, dynamic> map) {
    return OrderRealtimeClient(
      firstName: map['first_name'] as String? ?? '',
      lastName: map['last_name'] as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? '',
      email: map['email'] as String?,
    );
  }
}

class UberDelivery {
  const UberDelivery({
    required this.uberDeliveryPk,
    required this.uberDeliveryId,
    this.uberUuid,
    this.uberIdLast5,
    required this.attemptNumber,
    required this.deliveryRole,
    this.status,
    this.courierImminent,
    this.trackingUrl,
    this.pickupEta,
    this.pickupReady,
    this.pickupDeadline,
    this.pickupCompletedAt,
    this.dropoffEta,
    this.dropoffReady,
    this.dropoffDeadline,
    this.deliveredAt,
    this.courierName,
    this.courierPhoneNumber,
    this.courierImgHref,
    this.courierVehicleType,
    this.courierVehicleMake,
    this.courierVehicleModel,
    this.courierVehicleColor,
    this.courierVehicleLicensePlate,
    this.pickupAddress,
    this.dropoffAddress,
    this.cancellationReason,
    this.undeliverableReason,
    this.undeliverableAction,
    this.proofPictureUrl,
    this.signatureImageUrl,
    this.signatureSignerName,
    this.signatureSignerRelationship,
    this.integrationError,
    this.integrationErrorAt,
    this.createdAt,
  });

  final String uberDeliveryPk;
  final String uberDeliveryId;
  final String? uberUuid;
  final String? uberIdLast5;
  final int attemptNumber;
  final String deliveryRole; // forward | return | replacement | manual
  final String? status;
  final bool? courierImminent;
  final String? trackingUrl;
  final String? pickupEta;
  final String? pickupReady;
  final String? pickupDeadline;
  final String? pickupCompletedAt;
  final String? dropoffEta;
  final String? dropoffReady;
  final String? dropoffDeadline;
  final String? deliveredAt;
  final String? courierName;
  final String? courierPhoneNumber;
  final String? courierImgHref;
  final String? courierVehicleType;
  final String? courierVehicleMake;
  final String? courierVehicleModel;
  final String? courierVehicleColor;
  final String? courierVehicleLicensePlate;
  final String? pickupAddress;
  final String? dropoffAddress;
  final String? cancellationReason;
  final String? undeliverableReason;
  final String? undeliverableAction;
  final String? proofPictureUrl;
  final String? signatureImageUrl;
  final String? signatureSignerName;
  final String? signatureSignerRelationship;
  final String? integrationError;
  final String? integrationErrorAt;
  final String? createdAt;

  factory UberDelivery.fromMap(Map<String, dynamic> map) {
    return UberDelivery(
      uberDeliveryPk: map['uber_delivery_pk'] as String? ?? '',
      uberDeliveryId: map['uber_delivery_id'] as String? ?? '',
      uberUuid: map['uber_uuid'] as String?,
      uberIdLast5: map['uber_id_last5'] as String?,
      attemptNumber: _toInt(map['attempt_number']),
      deliveryRole: map['delivery_role'] as String? ?? 'forward',
      status: map['status'] as String?,
      courierImminent: map['courier_imminent'] as bool?,
      trackingUrl: map['tracking_url'] as String?,
      pickupEta: map['pickup_eta'] as String?,
      pickupReady: map['pickup_ready'] as String?,
      pickupDeadline: map['pickup_deadline'] as String?,
      pickupCompletedAt: map['pickup_completed_at'] as String?,
      dropoffEta: map['dropoff_eta'] as String?,
      dropoffReady: map['dropoff_ready'] as String?,
      dropoffDeadline: map['dropoff_deadline'] as String?,
      deliveredAt: map['delivered_at'] as String?,
      courierName: map['courier_name'] as String?,
      courierPhoneNumber: map['courier_phone_number'] as String?,
      courierImgHref: map['courier_img_href'] as String?,
      courierVehicleType: map['courier_vehicle_type'] as String?,
      courierVehicleMake: map['courier_vehicle_make'] as String?,
      courierVehicleModel: map['courier_vehicle_model'] as String?,
      courierVehicleColor: map['courier_vehicle_color'] as String?,
      courierVehicleLicensePlate:
          map['courier_vehicle_license_plate'] as String?,
      pickupAddress: map['pickup_address'] as String?,
      dropoffAddress: map['dropoff_address'] as String?,
      cancellationReason: map['cancellation_reason'] as String?,
      undeliverableReason: map['undeliverable_reason'] as String?,
      undeliverableAction: map['undeliverable_action'] as String?,
      proofPictureUrl: map['proof_picture_url'] as String?,
      signatureImageUrl: map['signature_image_url'] as String?,
      signatureSignerName: map['signature_signer_name'] as String?,
      signatureSignerRelationship:
          map['signature_signer_relationship'] as String?,
      integrationError: map['integration_error'] as String?,
      integrationErrorAt: map['integration_error_at'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }
}

typedef OrderStatus = String;

class OrderRealtimeOrder {
  const OrderRealtimeOrder({
    required this.orderId,
    required this.humanOrderNumber,
    required this.createdAt,
    required this.receiptUrl,
    required this.trackingLink,
    required this.orderStatus,
    required this.productsPrice,
    required this.deliveryPrice,
    required this.orderOptions,
    required this.uberDeliveryId,
    required this.uberCustomerId,
    required this.pickupReadyDt,
    required this.pickupDeadlineDt,
    required this.deliveryCreatedAt,
    required this.discountBreakdown,
    required this.client,
    required this.deliveryMethod,
    required this.items,
    this.uberDelivery,
  });

  final String orderId;
  final String? humanOrderNumber;
  final String createdAt;
  final String? receiptUrl;
  final String? trackingLink;
  final OrderStatus orderStatus;
  final double? productsPrice;
  final double? deliveryPrice;
  final dynamic orderOptions;
  final String? uberDeliveryId;
  final String? uberCustomerId;
  final String? pickupReadyDt;
  final String? pickupDeadlineDt;
  final String? deliveryCreatedAt;
  final OrderDiscountBreakdown? discountBreakdown;
  final OrderRealtimeClient client;
  final OrderRealtimeDeliveryMethod deliveryMethod;
  final List<OrderRealtimeItem> items;
  final UberDelivery? uberDelivery;

  OrderRealtimeOrder copyWith({
    String? orderId,
    String? humanOrderNumber,
    String? createdAt,
    String? receiptUrl,
    String? trackingLink,
    OrderStatus? orderStatus,
    double? productsPrice,
    double? deliveryPrice,
    Object? orderOptions = _sentinel,
    String? uberDeliveryId,
    String? uberCustomerId,
    String? pickupReadyDt,
    String? pickupDeadlineDt,
    String? deliveryCreatedAt,
    Object? discountBreakdown = _sentinel,
    OrderRealtimeClient? client,
    OrderRealtimeDeliveryMethod? deliveryMethod,
    List<OrderRealtimeItem>? items,
    Object? uberDelivery = _sentinel,
  }) {
    return OrderRealtimeOrder(
      orderId: orderId ?? this.orderId,
      humanOrderNumber: humanOrderNumber ?? this.humanOrderNumber,
      createdAt: createdAt ?? this.createdAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      trackingLink: trackingLink ?? this.trackingLink,
      orderStatus: orderStatus ?? this.orderStatus,
      productsPrice: productsPrice ?? this.productsPrice,
      deliveryPrice: deliveryPrice ?? this.deliveryPrice,
      orderOptions: identical(orderOptions, _sentinel)
          ? this.orderOptions
          : orderOptions,
      uberDeliveryId: uberDeliveryId ?? this.uberDeliveryId,
      uberCustomerId: uberCustomerId ?? this.uberCustomerId,
      pickupReadyDt: pickupReadyDt ?? this.pickupReadyDt,
      pickupDeadlineDt: pickupDeadlineDt ?? this.pickupDeadlineDt,
      deliveryCreatedAt: deliveryCreatedAt ?? this.deliveryCreatedAt,
      discountBreakdown: identical(discountBreakdown, _sentinel)
          ? this.discountBreakdown
          : discountBreakdown as OrderDiscountBreakdown?,
      client: client ?? this.client,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      items: items ?? this.items,
      uberDelivery: identical(uberDelivery, _sentinel)
          ? this.uberDelivery
          : uberDelivery as UberDelivery?,
    );
  }

  factory OrderRealtimeOrder.fromMap(Map<String, dynamic> map) {
    final itemList = map['items'] as List<dynamic>? ?? const [];

    return OrderRealtimeOrder(
      orderId: map['order_id'] as String? ?? '',
      humanOrderNumber: _toNullableString(map['human_order_number']),
      createdAt: map['created_at'] as String? ?? '',
      receiptUrl: _toNullableString(map['receipt_url']),
      trackingLink: map['tracking_link'] as String?,
      orderStatus: map['order_status'] as String? ?? '',
      productsPrice: map['products_price'] == null
          ? null
          : _toDouble(map['products_price']),
      deliveryPrice: map['delivery_price'] == null
          ? null
          : _toDouble(map['delivery_price']),
      orderOptions: map['order_options'],
      uberDeliveryId: map['uber_delivery_id'] as String?,
      uberCustomerId: map['uber_customer_id'] as String?,
      pickupReadyDt: map['pickup_ready_dt'] as String?,
      pickupDeadlineDt: map['pickup_deadline_dt'] as String?,
      deliveryCreatedAt: map['delivery_created_at'] as String?,
      discountBreakdown: map['discount_breakdown'] == null
          ? null
          : OrderDiscountBreakdown.fromMap(
              map['discount_breakdown'] as Map<String, dynamic>,
            ),
      client: OrderRealtimeClient.fromMap(
        map['client'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      deliveryMethod: OrderRealtimeDeliveryMethod.fromMap(
        map['delivery_method'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      items: itemList
          .map(
            (item) => OrderRealtimeItem.fromMap(item as Map<String, dynamic>),
          )
          .toList(),
      uberDelivery: map['uber_delivery'] is Map<String, dynamic>
          ? UberDelivery.fromMap(map['uber_delivery'] as Map<String, dynamic>)
          : null,
    );
  }
}

class OrderOptionDisplay {
  const OrderOptionDisplay.text({required this.label, required this.value})
    : type = OrderOptionDisplayType.text,
      mediaUrl = null;

  const OrderOptionDisplay.media({required this.label, required this.mediaUrl})
    : type = OrderOptionDisplayType.media,
      value = null;

  final OrderOptionDisplayType type;
  final String label;
  final String? value;
  final String? mediaUrl;
}

enum OrderOptionDisplayType { text, media }

class ProductOptionDisplay {
  const ProductOptionDisplay({
    required this.label,
    required this.values,
    required this.displayAsBullets,
  });

  final String label;
  final List<String> values;
  final bool displayAsBullets;
}

class OrderDetailOrder {
  const OrderDetailOrder({
    required this.orderId,
    required this.humanOrderNumber,
    required this.createdAt,
    required this.client,
    required this.paymentMethodName,
    required this.deliveryMethodName,
    required this.receiptUrl,
    required this.trackingLink,
    required this.orderStatus,
    required this.deliveryPrice,
    required this.productsPrice,
    required this.orderOptions,
    required this.uberDeliveryId,
    required this.productsPaymentStatus,
    required this.deliveryPaymentStatus,
    required this.discountBreakdown,
  });

  final String orderId;
  final String? humanOrderNumber;
  final String createdAt;
  final OrderRealtimeClient client;
  final String? paymentMethodName;
  final String? deliveryMethodName;
  final String? receiptUrl;
  final String? trackingLink;
  final String? orderStatus;
  final double? deliveryPrice;
  final double? productsPrice;
  final Object? orderOptions;
  final String? uberDeliveryId;
  final String? productsPaymentStatus;
  final String? deliveryPaymentStatus;
  final OrderDiscountBreakdown? discountBreakdown;

  factory OrderDetailOrder.fromMap(Map<String, dynamic> map) {
    return OrderDetailOrder(
      orderId: map['order_id'] as String? ?? '',
      humanOrderNumber: _toNullableString(map['human_order_number']),
      createdAt: map['created_at'] as String? ?? '',
      client: OrderRealtimeClient.fromMap(
        map['client'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      paymentMethodName: map['payment_method_name'] as String?,
      deliveryMethodName: map['delivery_method_name'] as String?,
      receiptUrl: _toNullableString(map['receipt_url']),
      trackingLink: map['tracking_link'] as String?,
      orderStatus: map['order_status'] as String?,
      deliveryPrice: map['delivery_price'] == null
          ? null
          : _toDouble(map['delivery_price']),
      productsPrice: map['products_price'] == null
          ? null
          : _toDouble(map['products_price']),
      orderOptions: map['options'],
      uberDeliveryId: map['uber_delivery_id'] as String?,
      productsPaymentStatus: map['products_payment_status'] as String?,
      deliveryPaymentStatus: map['delivery_payment_status'] as String?,
      discountBreakdown: map['discount_breakdown'] == null
          ? null
          : OrderDiscountBreakdown.fromMap(
              map['discount_breakdown'] as Map<String, dynamic>,
            ),
    );
  }
}

class OrderDetailItem {
  const OrderDetailItem({
    required this.name,
    required this.quantity,
    required this.image,
    required this.options,
  });

  final String name;
  final int quantity;
  final String? image;
  final Object? options;

  factory OrderDetailItem.fromMap(Map<String, dynamic> map) {
    return OrderDetailItem(
      name: map['name'] as String? ?? '',
      quantity: _toInt(map['quantity']),
      image: map['first_image'] as String?,
      options: map['options'],
    );
  }
}

class OrderDetailData {
  const OrderDetailData({required this.order, required this.items});

  final OrderDetailOrder order;
  final List<OrderDetailItem> items;

  factory OrderDetailData.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? const [];

    return OrderDetailData(
      order: OrderDetailOrder.fromMap(
        map['order'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      items: rawItems
          .whereType<Map>()
          .map((item) => OrderDetailItem.fromMap(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  OrderRealtimeOrder toRealtimeOrder() {
    return OrderRealtimeOrder(
      orderId: order.orderId,
      humanOrderNumber: order.humanOrderNumber,
      createdAt: order.createdAt,
      receiptUrl: order.receiptUrl,
      trackingLink: order.trackingLink,
      orderStatus: order.orderStatus ?? '',
      productsPrice: order.productsPrice,
      deliveryPrice: order.deliveryPrice,
      orderOptions: order.orderOptions,
      uberDeliveryId: order.uberDeliveryId,
      uberCustomerId: null,
      pickupReadyDt: null,
      pickupDeadlineDt: null,
      deliveryCreatedAt: null,
      discountBreakdown: order.discountBreakdown,
      client: order.client,
      deliveryMethod: OrderRealtimeDeliveryMethod(
        uid: '',
        name: order.deliveryMethodName ?? '',
        requireCourier: false,
        requireLocation: false,
      ),
      items: items
          .map(
            (item) => OrderRealtimeItem(
              quantity: item.quantity,
              totalPrice: 0,
              options: item.options,
              productVariantName: item.name,
              image: item.image,
            ),
          )
          .toList(growable: false),
    );
  }
}

class OrderDetailResponse {
  const OrderDetailResponse({required this.success, this.data, this.message});

  final bool success;
  final OrderDetailData? data;
  final String? message;

  factory OrderDetailResponse.fromMap(Map<String, dynamic> map) {
    return OrderDetailResponse(
      success: map['success'] as bool? ?? false,
      data: map['data'] is Map<String, dynamic>
          ? OrderDetailData.fromMap(map['data'] as Map<String, dynamic>)
          : null,
      message: map['message'] as String?,
    );
  }
}

class OrderActionResult {
  const OrderActionResult({required this.success, this.message, this.changed});

  final bool success;
  final String? message;
  final bool? changed;
}

class OrderSummaryClient {
  const OrderSummaryClient({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
  });

  final String firstName;
  final String lastName;
  final String phoneNumber;
}

class OrderSummary {
  const OrderSummary({
    required this.orderId,
    required this.humanOrderNumber,
    required this.createdAt,
    required this.amount,
    required this.client,
    required this.receiptUrl,
    required this.trackingLink,
    required this.orderStatus,
    required this.statusStartedAt,
    this.pickupReadyDt,
    this.uberDeliveryStatus,
    this.uberDeliveryId,
    this.requiresCourier = false,
    this.requiresLocation = false,
  });

  final String orderId;
  final String? humanOrderNumber;
  final String createdAt;
  final double? amount;
  final OrderSummaryClient client;
  final String? receiptUrl;
  final String? trackingLink;
  final OrderStatus orderStatus;
  final String statusStartedAt;
  final String? pickupReadyDt;
  final String? uberDeliveryStatus;
  final String? uberDeliveryId;
  final bool requiresCourier;
  final bool requiresLocation;

  OrderSummary copyWith({
    String? orderId,
    String? humanOrderNumber,
    String? createdAt,
    double? amount,
    OrderSummaryClient? client,
    String? receiptUrl,
    String? trackingLink,
    OrderStatus? orderStatus,
    String? statusStartedAt,
    Object? pickupReadyDt = _sentinel,
    Object? uberDeliveryStatus = _sentinel,
    Object? uberDeliveryId = _sentinel,
    bool? requiresCourier,
    bool? requiresLocation,
  }) {
    return OrderSummary(
      orderId: orderId ?? this.orderId,
      humanOrderNumber: humanOrderNumber ?? this.humanOrderNumber,
      createdAt: createdAt ?? this.createdAt,
      amount: amount ?? this.amount,
      client: client ?? this.client,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      trackingLink: trackingLink ?? this.trackingLink,
      orderStatus: orderStatus ?? this.orderStatus,
      statusStartedAt: statusStartedAt ?? this.statusStartedAt,
      pickupReadyDt: identical(pickupReadyDt, _sentinel)
          ? this.pickupReadyDt
          : pickupReadyDt as String?,
      uberDeliveryStatus: identical(uberDeliveryStatus, _sentinel)
          ? this.uberDeliveryStatus
          : uberDeliveryStatus as String?,
      uberDeliveryId: identical(uberDeliveryId, _sentinel)
          ? this.uberDeliveryId
          : uberDeliveryId as String?,
      requiresCourier: requiresCourier ?? this.requiresCourier,
      requiresLocation: requiresLocation ?? this.requiresLocation,
    );
  }
}

class OrderRealtimeResponse {
  const OrderRealtimeResponse({
    required this.success,
    this.data = const [],
    this.message,
  });

  final bool success;
  final List<OrderRealtimeOrder> data;
  final String? message;

  factory OrderRealtimeResponse.fromMap(Map<String, dynamic> map) {
    final rawData = map['data'];
    final list = rawData is List ? rawData : const [];

    return OrderRealtimeResponse(
      success: map['success'] as bool? ?? false,
      data: list
          .map(
            (item) => OrderRealtimeOrder.fromMap(item as Map<String, dynamic>),
          )
          .toList(),
      message: map['message'] as String?,
    );
  }
}

class OrdersTableRow {
  const OrdersTableRow({
    required this.orderId,
    required this.humanOrderNumber,
    required this.createdAt,
    required this.receiptUrl,
    required this.customerName,
    required this.total,
    required this.deliveryPrice,
    required this.orderStatus,
    required this.paymentStatus,
    required this.deliveryRequireCourier,
    required this.deliveryRequireLocation,
    required this.paymentManagedByBusiness,
  });

  final String orderId;
  final String? humanOrderNumber;
  final String createdAt;
  final String? receiptUrl;
  final String customerName;
  final double? total;
  final double? deliveryPrice;
  final String orderStatus;
  final String paymentStatus;
  final bool deliveryRequireCourier;
  final bool deliveryRequireLocation;
  final bool paymentManagedByBusiness;

  OrdersTableRow copyWith({
    String? orderId,
    String? humanOrderNumber,
    String? createdAt,
    String? receiptUrl,
    String? customerName,
    double? total,
    double? deliveryPrice,
    String? orderStatus,
    String? paymentStatus,
    bool? deliveryRequireCourier,
    bool? deliveryRequireLocation,
    bool? paymentManagedByBusiness,
  }) {
    return OrdersTableRow(
      orderId: orderId ?? this.orderId,
      humanOrderNumber: humanOrderNumber ?? this.humanOrderNumber,
      createdAt: createdAt ?? this.createdAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      customerName: customerName ?? this.customerName,
      total: total ?? this.total,
      deliveryPrice: deliveryPrice ?? this.deliveryPrice,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryRequireCourier:
          deliveryRequireCourier ?? this.deliveryRequireCourier,
      deliveryRequireLocation:
          deliveryRequireLocation ?? this.deliveryRequireLocation,
      paymentManagedByBusiness:
          paymentManagedByBusiness ?? this.paymentManagedByBusiness,
    );
  }

  factory OrdersTableRow.fromMap(Map<String, dynamic> map) {
    return OrdersTableRow(
      orderId: map['order_id'] as String? ?? '',
      humanOrderNumber: _toNullableString(map['human_order_number']),
      createdAt: map['created_at'] as String? ?? '',
      receiptUrl: _toNullableString(map['receipt_url']),
      customerName: map['customer_name'] as String? ?? '',
      total: map['total'] == null ? null : _toDouble(map['total']),
      deliveryPrice: map['delivery_price'] == null
          ? null
          : _toDouble(map['delivery_price']),
      orderStatus: map['order_status'] as String? ?? '',
      paymentStatus: map['payment_status'] as String? ?? '',
      deliveryRequireCourier: map['delivery_require_courier'] as bool? ?? false,
      deliveryRequireLocation:
          map['delivery_require_location'] as bool? ?? false,
      paymentManagedByBusiness:
          map['payment_managed_by_business'] as bool? ?? false,
    );
  }
}

class OrdersTablePagination {
  const OrdersTablePagination({
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  final int limit;
  final int offset;
  final bool hasMore;

  factory OrdersTablePagination.fromMap(Map<String, dynamic> map) {
    return OrdersTablePagination(
      limit: _toInt(map['limit']),
      offset: _toInt(map['offset']),
      hasMore: map['has_more'] as bool? ?? false,
    );
  }
}

class OrdersTableData {
  const OrdersTableData({required this.rows, required this.pagination});

  final List<OrdersTableRow> rows;
  final OrdersTablePagination pagination;

  factory OrdersTableData.fromMap(Map<String, dynamic> map) {
    final rawRows = map['rows'];
    final rows = rawRows is List ? rawRows : const [];

    return OrdersTableData(
      rows: rows
          .whereType<Map>()
          .map((item) => OrdersTableRow.fromMap(item.cast<String, dynamic>()))
          .toList(growable: false),
      pagination: OrdersTablePagination.fromMap(
        map['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

class OrdersTableResponse {
  const OrdersTableResponse({required this.success, this.data, this.message});

  final bool success;
  final OrdersTableData? data;
  final String? message;

  factory OrdersTableResponse.fromMap(Map<String, dynamic> map) {
    return OrdersTableResponse(
      success: map['success'] as bool? ?? false,
      data: map['data'] is Map<String, dynamic>
          ? OrdersTableData.fromMap(map['data'] as Map<String, dynamic>)
          : null,
      message: map['message'] as String?,
    );
  }
}

class ProductTableRow {
  const ProductTableRow({
    required this.productId,
    required this.name,
    required this.price,
    required this.categories,
    required this.images,
    required this.visibility,
  });

  final String productId;
  final String name;
  final double price;
  final List<String> categories;
  final List<String> images;
  final bool visibility;

  ProductTableRow copyWith({
    String? productId,
    String? name,
    double? price,
    List<String>? categories,
    List<String>? images,
    bool? visibility,
  }) {
    return ProductTableRow(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      categories: categories ?? this.categories,
      images: images ?? this.images,
      visibility: visibility ?? this.visibility,
    );
  }

  factory ProductTableRow.fromMap(Map<String, dynamic> map) {
    final rawCategories = map['categories'];
    final rawImages = map['images'];

    return ProductTableRow(
      productId: map['product_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: _toDouble(map['price']),
      categories: rawCategories is List
          ? rawCategories.map((item) => '$item').toList(growable: false)
          : const [],
      images: rawImages is List
          ? rawImages.map((item) => '$item').toList(growable: false)
          : const [],
      visibility: map['visibility'] as bool? ?? false,
    );
  }
}

class ProductVariantRow {
  const ProductVariantRow({
    required this.productVariantId,
    required this.name,
    required this.price,
    required this.visibleAtLocation,
  });

  final String productVariantId;
  final String name;
  final double price;
  final bool visibleAtLocation;

  ProductVariantRow copyWith({
    String? productVariantId,
    String? name,
    double? price,
    bool? visibleAtLocation,
  }) {
    return ProductVariantRow(
      productVariantId: productVariantId ?? this.productVariantId,
      name: name ?? this.name,
      price: price ?? this.price,
      visibleAtLocation: visibleAtLocation ?? this.visibleAtLocation,
    );
  }

  factory ProductVariantRow.fromMap(Map<String, dynamic> map) {
    return ProductVariantRow(
      productVariantId: map['product_variant_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: _toDouble(map['price']),
      visibleAtLocation: map['visible_at_location'] as bool? ?? true,
    );
  }
}

class ProductVariantVisibilityResult {
  const ProductVariantVisibilityResult({
    required this.success,
    this.message,
    this.productHidden = false,
    this.visibleAtLocation,
  });

  final bool success;
  final String? message;
  final bool productHidden;
  final bool? visibleAtLocation;
}

class ProductOptionChoiceRow {
  const ProductOptionChoiceRow({
    required this.productOptionChoiceId,
    required this.name,
    required this.price,
    required this.visibleAtLocation,
  });

  final String productOptionChoiceId;
  final String name;
  final double price;
  final bool visibleAtLocation;

  ProductOptionChoiceRow copyWith({
    String? productOptionChoiceId,
    String? name,
    double? price,
    bool? visibleAtLocation,
  }) {
    return ProductOptionChoiceRow(
      productOptionChoiceId:
          productOptionChoiceId ?? this.productOptionChoiceId,
      name: name ?? this.name,
      price: price ?? this.price,
      visibleAtLocation: visibleAtLocation ?? this.visibleAtLocation,
    );
  }

  factory ProductOptionChoiceRow.fromMap(Map<String, dynamic> map) {
    return ProductOptionChoiceRow(
      productOptionChoiceId: map['product_option_choice_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: _toDouble(map['price']),
      visibleAtLocation: map['visible_at_location'] as bool? ?? true,
    );
  }
}

class ProductOptionRow {
  const ProductOptionRow({
    required this.productOptionId,
    required this.name,
    required this.type,
    required this.sequence,
    required this.groupKind,
    required this.groupName,
    required this.choices,
  });

  final String productOptionId;
  final String name;
  final String type;
  final int sequence;
  final String groupKind;
  final String groupName;
  final List<ProductOptionChoiceRow> choices;

  ProductOptionRow copyWith({
    String? productOptionId,
    String? name,
    String? type,
    int? sequence,
    String? groupKind,
    String? groupName,
    List<ProductOptionChoiceRow>? choices,
  }) {
    return ProductOptionRow(
      productOptionId: productOptionId ?? this.productOptionId,
      name: name ?? this.name,
      type: type ?? this.type,
      sequence: sequence ?? this.sequence,
      groupKind: groupKind ?? this.groupKind,
      groupName: groupName ?? this.groupName,
      choices: choices ?? this.choices,
    );
  }

  factory ProductOptionRow.fromMap(Map<String, dynamic> map) {
    final rawChoices = map['choices'];
    return ProductOptionRow(
      productOptionId: map['product_option_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? '',
      sequence: _toInt(map['sequence']),
      groupKind: map['group_kind'] as String? ?? 'general',
      groupName: map['group_name'] as String? ?? '',
      choices: rawChoices is List
          ? rawChoices
                .whereType<Map>()
                .map(
                  (c) =>
                      ProductOptionChoiceRow.fromMap(c.cast<String, dynamic>()),
                )
                .toList(growable: false)
          : const [],
    );
  }
}

class PaymentMethodOption {
  const PaymentMethodOption({required this.uid, required this.name});

  final String uid;
  final String name;

  factory PaymentMethodOption.fromMap(Map<String, dynamic> map) {
    return PaymentMethodOption(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
    );
  }
}

class PaymentMethodsResponse {
  const PaymentMethodsResponse({
    required this.success,
    this.data = const [],
    this.message,
  });

  final bool success;
  final List<PaymentMethodOption> data;
  final String? message;

  factory PaymentMethodsResponse.fromMap(Map<String, dynamic> map) {
    final rawData = map['data'];
    final list = rawData is List ? rawData : const [];

    return PaymentMethodsResponse(
      success: map['success'] as bool? ?? false,
      data: list
          .whereType<Map>()
          .map(
            (item) => PaymentMethodOption.fromMap(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
      message: map['message'] as String?,
    );
  }
}

class OrderRealtimeRowUpdate {
  const OrderRealtimeRowUpdate({
    required this.orderId,
    required this.orderStatus,
    required this.productsPaymentStatus,
    required this.deliveryPaymentStatus,
    required this.commitTimestamp,
  });

  final String orderId;
  final String orderStatus;
  final String productsPaymentStatus;
  final String deliveryPaymentStatus;
  final DateTime commitTimestamp;

  factory OrderRealtimeRowUpdate.fromPayload(PostgresChangePayload payload) {
    final newRecord = payload.newRecord;

    return OrderRealtimeRowUpdate(
      orderId: newRecord['order_id'] as String? ?? '',
      orderStatus: newRecord['order_status'] as String? ?? '',
      productsPaymentStatus:
          newRecord['products_payment_status'] as String? ?? '',
      deliveryPaymentStatus:
          newRecord['delivery_payment_status'] as String? ?? '',
      commitTimestamp: payload.commitTimestamp,
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

String? _toNullableString(dynamic value) {
  if (value == null) return null;
  final normalized = '$value'.trim();
  return normalized.isEmpty ? null : normalized;
}

const Object _sentinel = Object();
