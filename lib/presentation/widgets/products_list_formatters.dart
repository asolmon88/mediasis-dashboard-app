import 'package:mediasis_dashboard_app/infrastructure/models/business_market_settings.dart';

String formatProductPrice(double value, {BusinessMarketSettings? market}) =>
    market?.formatMoney(value) ?? '-';

String mapProductVisibilityToSpanish(bool visibility) {
  return visibility ? 'Visible' : 'Oculto';
}
