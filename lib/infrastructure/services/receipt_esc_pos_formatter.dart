import 'dart:convert';

import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

class ReceiptEscPosFormatter {
  ReceiptEscPosFormatter();
  PaperSize _escPosPaperSize(PrinterPaperWidth width) =>
      width == PrinterPaperWidth.mm58 ? PaperSize.mm58 : PaperSize.mm72;

  Future<List<int>> buildTest(PrinterConfiguration printer) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(_escPosPaperSize(printer.paperWidth), profile);
    final bytes = <int>[
      ...generator.reset(),
      ...generator.text(
        ' MEDIASIS ',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
      ...generator.text(
        ' Impresora conectada correctamente ',
        styles: const PosStyles(align: PosAlign.center),
      ),
      ...generator.text(
        ' ${DateFormat('dd/MM/yyyy HH:mm', 'es_CR').format(DateTime.now())} ',
        styles: const PosStyles(align: PosAlign.center),
      ),
      ...generator.feed(3),
    ];
    if (printer.supportsCutter) bytes.addAll(generator.cut());
    return bytes;
  }

  Future<List<int>> build(
    ReceiptPrintPayload payload,
    PrinterConfiguration printer,
  ) async {
    final market = payload.market;
    if (market == null) throw StateError('MARKET_SETTINGS_MISSING');
    return _MarketReceiptFormatter(market).buildReceipt(payload, printer);
  }
}

// Per-job formatter: concurrent receipts must never share mutable market state.
class _MarketReceiptFormatter extends ReceiptEscPosFormatter {
  _MarketReceiptFormatter(this.market);
  final BusinessMarketSettings market;
  String label(String es, String en) =>
      market.locale.startsWith('en') ? en : es;

  Future<List<int>> buildReceipt(
    ReceiptPrintPayload payload,
    PrinterConfiguration printer,
  ) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(_escPosPaperSize(printer.paperWidth), profile);
    final bytes = <int>[...generator.reset()];
    bytes.addAll(
      generator.setGlobalFont(
        PosFontType.fontA,
        maxCharsPerLine: printer.paperWidth == PrinterPaperWidth.mm58 ? 32 : 40,
      ),
    );
    try {
      bytes.addAll(generator.setGlobalCodeTable('CP858'));
    } catch (_) {
      // Some printer profiles only expose their default Latin code table.
    }

    final logoUrl = _text(payload.business['logo']);
    if (logoUrl.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(logoUrl))
            .timeout(const Duration(seconds: 4));
        final logo = img.decodeImage(response.bodyBytes);
        if (response.statusCode == 200 && logo != null) {
          final resized = img.copyResize(logo, width: 180);
          bytes.addAll(generator.imageRaster(resized, align: PosAlign.center));
        }
      } catch (_) {
        // A logo must never prevent the textual receipt from printing.
      }
    }

    final businessName = _text(payload.business['name'], fallback: 'Mediasis');
    final locationName = _text(payload.order['business_location_name']);
    final businessHeader = locationName.isEmpty
        ? businessName
        : '$businessName - $locationName';
    final headerWidth = printer.paperWidth == PrinterPaperWidth.mm58 ? 32 : 40;
    final orderNumber = _text(
      payload.humanOrderNumber.isEmpty
          ? payload.orderId
          : payload.humanOrderNumber,
    );
    bytes.addAll(
      generator.text(
        _wrapText(businessHeader, headerWidth).join('\n'),
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    for (final businessLine in [
      _text(payload.business['domain']),
      _text(payload.business['phone_number']),
    ].where((line) => line.isNotEmpty)) {
      bytes.addAll(
        generator.text(
          businessLine,
          styles: const PosStyles(align: PosAlign.center),
        ),
      );
    }
    bytes
      ..addAll(generator.feed(1))
      ..addAll(
        generator.text(
          label('RECIBO', 'RECEIPT'),
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
      )
      ..addAll(
        generator.text(
          '#$orderNumber',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size1,
          ),
        ),
      )
      ..addAll(generator.hr());

    _detailBlock(
      bytes,
      generator,
      label('Fecha', 'Date'),
      _date(payload.order['created_at']),
    );
    _detailBlock(
      bytes,
      generator,
      label('Metodo de pago', 'Payment method'),
      _text(payload.order['payment_method_name'], fallback: 'Pendiente'),
    );
    _detailBlock(
      bytes,
      generator,
      label('Servicio', 'Service'),
      _text(payload.order['delivery_method_name'], fallback: 'No definido'),
    );
    _detailBlock(
      bytes,
      generator,
      label('Estado', 'Status'),
      _text(payload.order['order_status'], fallback: 'Pendiente'),
    );

    bytes
      ..addAll(generator.hr())
      ..addAll(generator.text('Items', styles: const PosStyles(bold: true)))
      ..addAll(generator.feed(1));
    for (final item in payload.items) {
      final itemName =
          '${item.quantity}x ${_text(item.name, fallback: 'Producto')}';
      for (final line in _twoColumnLines(
        itemName,
        _money(item.displayUnitPrice),
        headerWidth,
      )) {
        bytes.addAll(generator.text(line, styles: const PosStyles(bold: true)));
      }
      bytes.addAll(
        generator.text(
          _money(item.lineTotal),
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      );
      if (item.variantName.isNotEmpty && item.variantName != item.name) {
        bytes.addAll(
          generator.text(
            '  ${_text(item.variantName)}',
            styles: const PosStyles(bold: true),
          ),
        );
      }
      for (final line in _itemOptionLines(item.options)) {
        for (final wrapped in _wrapText('- $line', headerWidth - 2)) {
          bytes.addAll(
            generator.text('  $wrapped', styles: const PosStyles(bold: true)),
          );
        }
      }
      bytes.addAll(generator.feed(1));
    }

    bytes
      ..addAll(generator.hr())
      ..addAll(
        generator.text(
          label('Totales', 'Totals'),
          styles: const PosStyles(bold: true),
        ),
      )
      ..addAll(generator.feed(1));
    final productsPrice = _number(payload.order['products_price']);
    _moneyRow(
      bytes,
      generator,
      label('Productos', 'Products'),
      productsPrice,
      headerWidth,
    );
    final discount = _number(payload.order['discount_amount']);
    if (discount > 0) {
      final discountCode = _text(payload.order['discount_code']);
      _moneyRow(
        bytes,
        generator,
        discountCode.isEmpty
            ? label('Descuento', 'Discount')
            : "${label('Descuento', 'Discount')} $discountCode",
        -discount,
        headerWidth,
      );
    }
    final charged = (productsPrice - discount).clamp(0, double.infinity);
    bytes
      ..addAll(generator.hr())
      ..addAll(
        generator.row([
          PosColumn(
            text: 'Total',
            width: 5,
            styles: const PosStyles(bold: true),
          ),
          PosColumn(
            text: _money(charged),
            width: 7,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]),
      )
      ..addAll(generator.feed(1));

    final cashbackEarned =
        _number(payload.order['cashback_earned_minor']) / 100;
    if (cashbackEarned > 0) {
      bytes
        ..addAll(generator.hr())
        ..addAll(
          generator.text('Cashback', styles: const PosStyles(bold: true)),
        )
        ..addAll(generator.feed(1));
      final status = _text(payload.order['cashback_earning_status']);
      final cashbackLabel = status == 'available'
          ? label('Cashback acumulado', 'Cashback earned')
          : status == 'pending'
          ? label('Pendiente hasta entregar', 'Pending until delivery')
          : label('Cashback revertido', 'Cashback reversed');
      _moneyRow(bytes, generator, cashbackLabel, cashbackEarned, headerWidth);
    }
    _section(bytes, generator, label('Cliente', 'Customer'), [
      _text(payload.customer['full_name']),
      _text(payload.customer['phone']),
      _text(payload.customer['email']),
    ], headerWidth);

    final detailLines = _additionalDetailLines(payload.additionalDetails);
    final deliveryNote = _text(payload.order['delivery_note']);
    if (deliveryNote.isNotEmpty) {
      detailLines.add(
        "${label('Nota de entrega', 'Delivery note')}: $deliveryNote",
      );
    }
    final mapUrl = _mapsUrl(
      payload.order['drop_off_lat'],
      payload.order['drop_off_lng'],
    );
    if (mapUrl != null) detailLines.add("${label('Mapa', 'Map')}: $mapUrl");
    final tracking = _text(payload.order['tracking_link']);
    if (tracking.isNotEmpty) detailLines.add('Tracking: $tracking');
    final pickup = _text(payload.order['pickup_ready_dt']);
    if (pickup.isNotEmpty) {
      detailLines.add(
        "${label('Hora estimada', 'Estimated time')}: ${_date(pickup)}",
      );
    }
    _section(
      bytes,
      generator,
      label('Detalles adicionales', 'Additional details'),
      detailLines,
      headerWidth,
    );

    if (mapUrl != null) {
      bytes
        ..addAll(
          generator.text(
            label('Mapa', 'Map'),
            styles: const PosStyles(align: PosAlign.center, bold: true),
          ),
        )
        ..addAll(generator.qrcode(mapUrl, size: QRSize.size3));
    }
    if (tracking.isNotEmpty) {
      bytes
        ..addAll(
          generator.text(
            label('Rastreo', 'Tracking'),
            styles: const PosStyles(align: PosAlign.center, bold: true),
          ),
        )
        ..addAll(generator.qrcode(tracking, size: QRSize.size3));
    }
    bytes
      ..addAll(generator.hr())
      ..addAll(
        generator.text(
          'mediasis',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
      );
    bytes.addAll(generator.feed(3));
    if (printer.supportsCutter) {
      bytes.addAll(generator.cut());
    }
    return bytes;
  }

  List<String> _itemOptionLines(dynamic raw) {
    final options = _object(raw);
    final lines = <String>[];
    for (final type in const ['selection', 'checkbox']) {
      for (final entry in _objects(options[type])) {
        final name = _text(entry['name']);
        final choices = type == 'selection'
            ? [_object(entry['choice'])]
            : _objects(entry['choices']);
        for (final choice in choices) {
          final label = _choiceLabel(choice);
          if (name.isNotEmpty && label.isNotEmpty) lines.add('$name: $label');
        }
      }
    }
    for (final type in const ['text', 'number', 'date', 'media']) {
      for (final entry in _objects(options[type])) {
        final name = _text(entry['name']);
        final value = _text(entry['value']);
        if (name.isNotEmpty && value.isNotEmpty) lines.add('$name: $value');
      }
    }
    return lines;
  }

  List<String> _additionalDetailLines(dynamic raw) {
    final lines = <String>[];
    for (final entry in _objects(raw)) {
      final type = _text(entry['type']);
      final question = _text(entry['question']);
      if (type == 'text') {
        final text = _text(entry['text']);
        if (text.isNotEmpty) lines.add(text);
      } else if (type == 'select') {
        final label = _choiceLabel(_object(entry['value']));
        if (question.isNotEmpty && label.isNotEmpty) {
          lines.add('$question: $label');
        }
      } else if (type == 'checkbox') {
        for (final choice in _objects(entry['value'])) {
          final label = _choiceLabel(choice);
          if (question.isNotEmpty && label.isNotEmpty) {
            lines.add('$question: $label');
          }
        }
      } else {
        final value = _text(entry['value']);
        if (question.isNotEmpty && value.isNotEmpty) {
          lines.add('$question: $value');
        }
      }
    }
    return lines;
  }

  String _choiceLabel(Map<String, dynamic> choice) {
    final name = _text(choice['choice']);
    if (name.isEmpty) return '';
    final quantity = _number(choice['quantity']);
    final price = _number(choice['price']);
    return '$name${quantity > 0 ? ' (${quantity.toInt()})' : ''}${price > 0 ? ' +${_money(price)}' : ''}';
  }

  void _section(
    List<int> bytes,
    Generator generator,
    String title,
    List<String> lines,
    int columns,
  ) {
    final visible = lines.where((line) => line.trim().isNotEmpty).toList();
    if (visible.isEmpty) return;
    bytes
      ..addAll(generator.hr())
      ..addAll(generator.text(title))
      ..addAll(generator.feed(1));
    for (final line in visible) {
      for (final wrapped in _wrapText(line, columns)) {
        bytes.addAll(generator.text(wrapped));
      }
    }
  }

  void _detailBlock(
    List<int> bytes,
    Generator generator,
    String label,
    String value,
  ) {
    bytes
      ..addAll(generator.text(label))
      ..addAll(generator.text(value))
      ..addAll(generator.feed(1));
  }

  void _moneyRow(
    List<int> bytes,
    Generator generator,
    String label,
    dynamic value,
    int columns,
  ) {
    for (final line in _twoColumnLines(label, _money(value), columns)) {
      bytes.addAll(generator.text(line));
    }
  }

  String _money(dynamic value) => _text(market.formatMoney(_number(value)));

  List<String> _twoColumnLines(String left, String right, int columns) {
    final cleanLeft = _text(left);
    final cleanRight = _text(right);
    final minimumGap = 1;
    final leftWidth = (columns - cleanRight.length - minimumGap).clamp(
      8,
      columns,
    );
    final wrapped = _wrapText(cleanLeft, leftWidth);
    if (wrapped.isEmpty) return [cleanRight.padLeft(columns)];
    final lines = <String>[];
    for (var index = 0; index < wrapped.length; index++) {
      final line = wrapped[index];
      if (index == wrapped.length - 1 &&
          line.length + minimumGap + cleanRight.length <= columns) {
        lines.add(
          '$line${' ' * (columns - line.length - cleanRight.length)}$cleanRight',
        );
      } else {
        lines.add(line);
      }
    }
    if (!lines.last.endsWith(cleanRight)) {
      lines.add(cleanRight.padLeft(columns));
    }
    return lines;
  }

  List<String> _wrapText(String value, int maxCharacters) {
    final words = value.trim().split(RegExp(r'\s+'));
    final lines = <String>[];
    var current = '';
    for (final word in words) {
      if (word.length > maxCharacters) {
        if (current.isNotEmpty) {
          lines.add(current);
          current = '';
        }
        for (var start = 0; start < word.length; start += maxCharacters) {
          lines.add(
            word.substring(
              start,
              (start + maxCharacters).clamp(0, word.length),
            ),
          );
        }
        continue;
      }
      final candidate = current.isEmpty ? word : '$current $word';
      if (candidate.length <= maxCharacters) {
        current = candidate;
      } else {
        lines.add(current);
        current = word;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(_text(value));
    return date == null ? 'Pendiente' : _text(market.formatDate(date));
  }

  String? _mapsUrl(dynamic lat, dynamic lng) {
    final latitude = double.tryParse(_text(lat));
    final longitude = double.tryParse(_text(lng));
    return latitude == null || longitude == null
        ? null
        : 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  Map<String, dynamic> _object(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _objects(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      try {
        value = jsonDecode(value);
      } catch (_) {
        return const [];
      }
    }
    return value is List
        ? value
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList()
        : const [];
  }

  num _number(dynamic value) =>
      value is num ? value : num.tryParse('$value') ?? 0;
  String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    final resolved = text.isEmpty || text == 'null' ? fallback : text;
    return _ascii(resolved);
  }

  String _ascii(String value) {
    const replacements = <String, String>{
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
      'Ñ': 'N',
      '“': '"',
      '”': '"',
      '‘': "'",
      '’': "'",
      '–': '-',
      '—': '-',
      '…': '...',
    };
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final character = String.fromCharCode(rune);
      final replacement = replacements[character];
      if (replacement != null) {
        buffer.write(replacement);
      } else if (rune >= 0x20 && rune <= 0x7e) {
        buffer.write(character);
      } else if (rune == 0x0a) {
        buffer.write('\n');
      } else {
        buffer.write(' ');
      }
    }
    return buffer.toString().replaceAll(RegExp(r' {2,}'), ' ').trim();
  }
}
