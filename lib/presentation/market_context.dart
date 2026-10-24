import 'package:mediasis_dashboard_app/infrastructure/models/business_market_settings.dart';
import 'package:mediasis_dashboard_app/presentation/bloc/location_cubit/location_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension MarketContext on BuildContext {
  BusinessMarketSettings? get market => watch<LocationCubit>().state.market;
}
