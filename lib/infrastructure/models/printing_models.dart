import 'package:mediasis_dashboard_app/infrastructure/models/business_market_settings.dart';
import 'dart:convert';

enum PrinterPaperWidth { mm58, mm80 }

enum PrinterConnectionType { network, sunmiBuiltIn }

enum PrinterReceiptFormat { visualRaster, escPosText }

class SunmiPrinterInfo {
  const SunmiPrinterInfo({
    required this.available,
    this.model = '',
    this.deviceModel = '',
    this.paperWidth = PrinterPaperWidth.mm58,
    this.printerState = 0,
    this.serviceStatus = '',
  });

  final bool available;
  final String model;
  final String deviceModel;
  final PrinterPaperWidth paperWidth;
  final int printerState;
  final String serviceStatus;
}

class PrinterConnectionException implements Exception {
  const PrinterConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PrinterConfiguration {
  const PrinterConfiguration({
    required this.id,
    required this.businessLocationId,
    required this.name,
    this.host = '',
    this.port = 9100,
    this.connectionType = PrinterConnectionType.network,
    this.receiptFormat = PrinterReceiptFormat.escPosText,
    this.deviceModel,
    this.paperWidth = PrinterPaperWidth.mm80,
    this.supportsCutter = true,
    this.automaticPrinting = false,
    this.verified = false,
    this.lastTestedAt,
    this.lastTestError,
  });

  final String id;
  final String businessLocationId;
  final String name;
  final String host;
  final int port;
  final PrinterConnectionType connectionType;
  final PrinterReceiptFormat receiptFormat;
  final String? deviceModel;
  final PrinterPaperWidth paperWidth;
  final bool supportsCutter;
  final bool automaticPrinting;
  final bool verified;
  final DateTime? lastTestedAt;
  final String? lastTestError;

  PrinterConfiguration copyWith({
    String? name,
    String? host,
    int? port,
    PrinterConnectionType? connectionType,
    PrinterReceiptFormat? receiptFormat,
    String? deviceModel,
    PrinterPaperWidth? paperWidth,
    bool? supportsCutter,
    bool? automaticPrinting,
    bool? verified,
    DateTime? lastTestedAt,
    String? lastTestError,
    bool clearLastTestError = false,
  }) => PrinterConfiguration(
    id: id,
    businessLocationId: businessLocationId,
    name: name ?? this.name,
    host: host ?? this.host,
    port: port ?? this.port,
    connectionType: connectionType ?? this.connectionType,
    receiptFormat: receiptFormat ?? this.receiptFormat,
    deviceModel: deviceModel ?? this.deviceModel,
    paperWidth: paperWidth ?? this.paperWidth,
    supportsCutter: supportsCutter ?? this.supportsCutter,
    automaticPrinting: automaticPrinting ?? this.automaticPrinting,
    verified: verified ?? this.verified,
    lastTestedAt: lastTestedAt ?? this.lastTestedAt,
    lastTestError: clearLastTestError
        ? null
        : lastTestError ?? this.lastTestError,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'business_location_id': businessLocationId,
    'name': name,
    'host': host,
    'port': port,
    'connection_type': connectionType.name,
    'receipt_format': receiptFormat.name,
    'device_model': deviceModel,
    'paper_width': paperWidth.name,
    'supports_cutter': supportsCutter,
    'automatic_printing': automaticPrinting,
    'verified': verified,
    'last_tested_at': lastTestedAt?.toIso8601String(),
    'last_test_error': lastTestError,
  };

  factory PrinterConfiguration.fromMap(Map<String, dynamic> map) =>
      PrinterConfiguration(
        id: '${map['id'] ?? ''}',
        businessLocationId: '${map['business_location_id'] ?? ''}',
        name: '${map['name'] ?? ''}',
        host: '${map['host'] ?? ''}',
        port: _integer(map['port'], fallback: 9100),
        connectionType: map['connection_type'] == 'sunmiBuiltIn'
            ? PrinterConnectionType.sunmiBuiltIn
            : PrinterConnectionType.network,
        receiptFormat: map['receipt_format'] == 'visualRaster'
            ? PrinterReceiptFormat.visualRaster
            : PrinterReceiptFormat.escPosText,
        deviceModel: map['device_model'] as String?,
        paperWidth: map['paper_width'] == 'mm58'
            ? PrinterPaperWidth.mm58
            : PrinterPaperWidth.mm80,
        supportsCutter: map['supports_cutter'] == true,
        automaticPrinting: map['automatic_printing'] == true,
        verified: map['verified'] == true,
        lastTestedAt: DateTime.tryParse('${map['last_tested_at'] ?? ''}'),
        lastTestError: map['last_test_error'] as String?,
      );
}

class DiscoveredPrinter {
  const DiscoveredPrinter({
    required this.name,
    required this.host,
    required this.port,
    required this.source,
  });

  final String name;
  final String host;
  final int port;
  final String source;
}

enum PrintJobTrigger { automatic, manual, retry, test }

enum PrintJobStatus { printing, printed, failed }

class IncomingOrderArrival {
  const IncomingOrderArrival({
    required this.orderId,
    required this.businessLocationId,
  });

  final String orderId;
  final String businessLocationId;
}

class PrintOperationResult {
  const PrintOperationResult({
    required this.successCount,
    required this.failureCount,
    this.formatsUsed = const {},
  });

  final int successCount;
  final int failureCount;
  final Set<PrintReceiptOutputFormat> formatsUsed;
  bool get success => successCount > 0 && failureCount == 0;
  bool get usedTextFallback =>
      formatsUsed.contains(PrintReceiptOutputFormat.escPosTextFallback);
}

enum PrintReceiptOutputFormat { visualRaster, escPosText, escPosTextFallback }

class PrintJob {
  const PrintJob({
    required this.id,
    required this.businessLocationId,
    required this.orderId,
    required this.printerId,
    required this.printerName,
    required this.trigger,
    required this.status,
    required this.attemptedAt,
    this.humanOrderNumber,
    this.error,
  });

  final String id;
  final String businessLocationId;
  final String orderId;
  final String printerId;
  final String printerName;
  final PrintJobTrigger trigger;
  final PrintJobStatus status;
  final DateTime attemptedAt;
  final String? humanOrderNumber;
  final String? error;

  PrintJob copyWith({PrintJobStatus? status, String? error}) => PrintJob(
    id: id,
    businessLocationId: businessLocationId,
    orderId: orderId,
    printerId: printerId,
    printerName: printerName,
    trigger: trigger,
    status: status ?? this.status,
    attemptedAt: attemptedAt,
    humanOrderNumber: humanOrderNumber,
    error: error,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'business_location_id': businessLocationId,
    'order_id': orderId,
    'printer_id': printerId,
    'printer_name': printerName,
    'trigger': trigger.name,
    'status': status.name,
    'attempted_at': attemptedAt.toIso8601String(),
    'human_order_number': humanOrderNumber,
    'error': error,
  };

  factory PrintJob.fromMap(Map<String, dynamic> map) => PrintJob(
    id: '${map['id'] ?? ''}',
    businessLocationId: '${map['business_location_id'] ?? ''}',
    orderId: '${map['order_id'] ?? ''}',
    printerId: '${map['printer_id'] ?? ''}',
    printerName: '${map['printer_name'] ?? ''}',
    trigger: PrintJobTrigger.values.firstWhere(
      (value) => value.name == map['trigger'],
      orElse: () => PrintJobTrigger.manual,
    ),
    status: PrintJobStatus.values.firstWhere(
      (value) => value.name == map['status'],
      orElse: () => PrintJobStatus.failed,
    ),
    attemptedAt:
        DateTime.tryParse('${map['attempted_at'] ?? ''}') ?? DateTime.now(),
    humanOrderNumber: map['human_order_number']?.toString(),
    error: map['error'] as String?,
  );
}

class ReceiptPrintPayload {
  const ReceiptPrintPayload({
    required this.business,
    required this.order,
    required this.customer,
    required this.items,
    required this.additionalDetails,
    this.market,
  });

  final Map<String, dynamic> business;
  final Map<String, dynamic> order;
  final Map<String, dynamic> customer;
  final List<ReceiptPrintItem> items;
  final dynamic additionalDetails;
  final BusinessMarketSettings? market;

  String get orderId => '${order['order_id'] ?? ''}';
  String get humanOrderNumber => '${order['human_order_number'] ?? ''}';

  factory ReceiptPrintPayload.fromMap(Map<String, dynamic> map) =>
      ReceiptPrintPayload(
        market: map['market'] is Map
            ? BusinessMarketSettings.fromMap(_map(map['market']))
            : null,
        business: _map(map['business']),
        order: _map(map['order']),
        customer: _map(map['customer']),
        items: _list(
          map['items'],
        ).map((item) => ReceiptPrintItem.fromMap(_map(item))).toList(),
        additionalDetails: map['additional_details'],
      );
}

class ReceiptPrintItem {
  const ReceiptPrintItem({
    required this.name,
    required this.variantName,
    required this.quantity,
    required this.baseUnitPrice,
    required this.displayUnitPrice,
    required this.lineTotal,
    required this.options,
  });

  final String name;
  final String variantName;
  final int quantity;
  final num baseUnitPrice;
  final num displayUnitPrice;
  final num lineTotal;
  final dynamic options;

  factory ReceiptPrintItem.fromMap(Map<String, dynamic> map) =>
      ReceiptPrintItem(
        name: '${map['name'] ?? ''}',
        variantName: '${map['variant_name'] ?? ''}',
        quantity: _integer(map['quantity'], fallback: 1),
        baseUnitPrice: _number(map['base_unit_price']),
        displayUnitPrice: _number(map['display_unit_price']),
        lineTotal: _number(map['line_total']),
        options: map['options'],
      );
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<dynamic> _list(dynamic value) {
  if (value is List) return value;
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      return decoded is List ? decoded : const [];
    } catch (_) {
      return const [];
    }
  }
  return const [];
}

num _number(dynamic value) =>
    value is num ? value : num.tryParse('$value') ?? 0;
int _integer(dynamic value, {required int fallback}) =>
    value is int ? value : int.tryParse('$value') ?? fallback;
