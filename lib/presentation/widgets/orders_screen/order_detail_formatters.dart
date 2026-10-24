import 'package:mediasis_dashboard_app/infrastructure/models.dart';

String formatCurrencyValue(double? value, {BusinessMarketSettings? market}) =>
    market?.formatMoney(value) ?? '-';

typedef _OrderOptionValue = Object?;

String _formatChoice(
  String? choice,
  double? price,
  BusinessMarketSettings? market,
) {
  if (choice == null || choice.isEmpty) return '';
  if (price != null && price.isFinite && price > 0) {
    return '$choice (${formatCurrencyValue(price, market: market)})';
  }
  return choice;
}

String _formatChoiceWithQuantity(
  String? choice,
  double? price,
  Object? quantity,
  BusinessMarketSettings? market,
) {
  final formattedChoice = _formatChoice(choice, price, market);
  if (formattedChoice.isEmpty) return '';

  if (quantity is! num || !quantity.isFinite || quantity <= 1) {
    return formattedChoice;
  }

  final quantityLabel = quantity == quantity.roundToDouble()
      ? '${quantity.round()}'
      : '$quantity';
  return '$formattedChoice ($quantityLabel)';
}

List<OrderOptionDisplay> formatOrderOptions(
  Object? options, {
  BusinessMarketSettings? market,
}) {
  if (options is! List) return const [];

  return options
      .whereType<Map>()
      .map((option) => option.cast<String, dynamic>())
      .map<OrderOptionDisplay?>((option) {
        final type = option['type'] as String? ?? '';
        final question = option['question'] as String? ?? 'Opcion';
        final value = option['value'] as _OrderOptionValue;

        if (type == 'short_answer' && value is String) {
          return OrderOptionDisplay.text(label: question, value: value);
        }

        if (type == 'select' && value is Map) {
          final map = value.cast<String, dynamic>();
          return OrderOptionDisplay.text(
            label: question,
            value: _formatChoice(
              map['choice'] as String?,
              _toDouble(map['price']),
              market,
            ),
          );
        }

        if (type == 'checkbox' && value is List) {
          final choices = value
              .whereType<Map>()
              .map((choice) => choice.cast<String, dynamic>())
              .map(
                (choice) => _formatChoice(
                  choice['choice'] as String?,
                  _toDouble(choice['price']),
                  market,
                ),
              )
              .where((choice) => choice.isNotEmpty)
              .join(', ');

          if (choices.isEmpty) return null;

          return OrderOptionDisplay.text(label: question, value: choices);
        }

        if (type == 'media' && value is String && value.isNotEmpty) {
          return OrderOptionDisplay.media(label: question, mediaUrl: value);
        }

        return null;
      })
      .whereType<OrderOptionDisplay>()
      .toList(growable: false);
}

List<ProductOptionDisplay> formatProductOptions(
  Object? options, {
  BusinessMarketSettings? market,
}) {
  if (options is! Map) return const [];

  final data = options.cast<String, dynamic>();
  final checkboxGroups = data['checkbox'] is List
      ? data['checkbox'] as List
      : const [];
  final selectionGroups = data['selection'] is List
      ? data['selection'] as List
      : const [];
  final textGroups = data['text'] is List ? data['text'] as List : const [];

  final checkboxLines = checkboxGroups
      .whereType<Map>()
      .map((group) => group.cast<String, dynamic>())
      .map((group) {
        final choices =
            (group['choices'] is List ? group['choices'] as List : const [])
                .whereType<Map>()
                .map((choice) => choice.cast<String, dynamic>())
                .map(
                  (choice) => _formatChoiceWithQuantity(
                    choice['choice'] as String?,
                    _toDouble(choice['price']),
                    choice['quantity'],
                    market,
                  ),
                )
                .where((choice) => choice.isNotEmpty)
                .toList(growable: false);

        if (choices.isEmpty) return null;
        return ProductOptionDisplay(
          label: '${group['name'] ?? 'Opcion'}',
          values: choices,
          displayAsBullets: true,
        );
      })
      .whereType<ProductOptionDisplay>();

  final selectionLines = selectionGroups
      .whereType<Map>()
      .map((group) => group.cast<String, dynamic>())
      .map((group) {
        final choice = group['choice'];
        if (choice is! Map) return null;
        final choiceMap = choice.cast<String, dynamic>();
        final formattedChoice = _formatChoiceWithQuantity(
          choiceMap['choice'] as String?,
          _toDouble(choiceMap['price']),
          choiceMap['quantity'],
          market,
        );
        if (formattedChoice.isEmpty) return null;
        return ProductOptionDisplay(
          label: '${group['name'] ?? 'Opcion'}',
          values: [formattedChoice],
          displayAsBullets: true,
        );
      })
      .whereType<ProductOptionDisplay>();

  final textLines = textGroups
      .whereType<Map>()
      .map((entry) => entry.cast<String, dynamic>())
      .map((entry) {
        final value = (entry['value'] as String?)?.trim() ?? '';
        if (value.isEmpty) return null;
        final name = (entry['name'] as String?)?.trim() ?? '';
        return ProductOptionDisplay(
          label: name.isEmpty ? 'Nota' : name,
          values: [value],
          displayAsBullets: false,
        );
      })
      .whereType<ProductOptionDisplay>();

  return [...selectionLines, ...checkboxLines, ...textLines];
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value == null) return null;
  return double.tryParse('$value');
}
