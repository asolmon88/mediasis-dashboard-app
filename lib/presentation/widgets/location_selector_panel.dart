import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

class LocationSelectorPanel extends StatefulWidget {
  const LocationSelectorPanel({super.key});

  @override
  State<LocationSelectorPanel> createState() => _LocationSelectorPanelState();
}

class _LocationSelectorPanelState extends State<LocationSelectorPanel> {
  final _searchController = TextEditingController();
  Position? _devicePosition;

  Future<void> _signOut() async {
    try {
      await context
          .read<PushNotificationsCubit>()
          .disableBeforeSignOut()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // A revoked or offline session must never prevent local sign-out.
    } finally {
      if (mounted) {
        await context.read<AuthCubit>().signOut();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _fetchDevicePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDevicePosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (mounted) setState(() => _devicePosition = position);
    } catch (_) {
      // silently ignore — list remains in original order
    }
  }

  List<BusinessLocation> _displayList(List<BusinessLocation> locations) {
    final q = _searchController.text.toLowerCase();
    var list = q.isEmpty
        ? locations
        : locations
              .where((l) => l.shortName.toLowerCase().contains(q))
              .toList();

    if (_devicePosition != null) {
      list = [...list]
        ..sort((a, b) {
          final da = Geolocator.distanceBetween(
            _devicePosition!.latitude,
            _devicePosition!.longitude,
            double.tryParse(a.lat) ?? 0,
            double.tryParse(a.lng) ?? 0,
          );
          final db = Geolocator.distanceBetween(
            _devicePosition!.latitude,
            _devicePosition!.longitude,
            double.tryParse(b.lat) ?? 0,
            double.tryParse(b.lng) ?? 0,
          );
          return da.compareTo(db);
        });
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(2.2.ws(context).clamp(18.0, 24.0)),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2.4.ws(context).clamp(16.0, 24.0),
            offset: Offset(0, 1.2.hs(context).clamp(8.0, 12.0)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(2.4.ws(context).clamp(20.0, 28.0)),
        child: BlocBuilder<LocationCubit, LocationState>(
          builder: (context, state) {
            final displayList = _displayList(state.locations);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'lib/assets/mediasis-orders-logo.png',
                  height: 2.4.hs(context).clamp(42.0, 64.0),
                  alignment: Alignment.centerLeft,
                ),
                SizedBox(height: 2.2.hs(context)),
                LocalizedText(
                  'Selecciona un local',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 1.hs(context)),
                LocalizedText(
                  'Elige el local con el que trabajaras en esta tablet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (state.errorMessage.isNotEmpty) ...[
                  SizedBox(height: 2.hs(context)),
                  LocalizedText(
                    state.errorMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  if (state.status == LocationStatus.failure) ...[
                    SizedBox(height: 1.6.hs(context)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () {
                          context.read<LocationCubit>().loadLocations();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const LocalizedText('Reintentar'),
                      ),
                    ),
                  ],
                ],
                if (state.locations.length > 3 ||
                    _searchController.text.isNotEmpty) ...[
                  SizedBox(height: 1.8.hs(context)),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: context.tr('Buscar local…'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          1.6.ws(context).clamp(12.0, 16.0),
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 2.ws(context).clamp(12.0, 16.0),
                        vertical: 1.2.hs(context).clamp(10.0, 14.0),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 1.8.hs(context)),
                if (displayList.isEmpty && _searchController.text.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.hs(context)),
                    child: LocalizedText(
                      'No hay resultados para "${_searchController.text}".',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ...displayList.map(
                    (location) => Padding(
                      padding: EdgeInsets.only(bottom: 1.5.hs(context)),
                      child: _LocationCard(location: location),
                    ),
                  ),
                SizedBox(height: 1.hs(context)),
                const Divider(),
                SizedBox(height: 0.5.hs(context)),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, authState) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        button: true,
                        label: context.tr('Cerrar sesión'),
                        child: TextButton.icon(
                          onPressed: authState.isLoading ? null : _signOut,
                          icon: authState.isLoading
                              ? SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : const Icon(Icons.logout_rounded),
                          label: const LocalizedText('Cerrar sesión'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location});

  final BusinessLocation location;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LocationCubit>().state;
    final isSelected =
        state.selectedLocation?.businessLocationId ==
        location.businessLocationId;

    return InkWell(
      borderRadius: BorderRadius.circular(2.ws(context).clamp(16.0, 20.0)),
      onTap: () => context.read<LocationCubit>().selectLocation(location),
      child: Ink(
        padding: EdgeInsets.all(2.2.ws(context).clamp(16.0, 20.0)),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Colors.white,
          borderRadius: BorderRadius.circular(2.ws(context).clamp(16.0, 20.0)),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.storefront_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
            ),
            SizedBox(width: 1.4.ws(context).clamp(12.0, 16.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.shortName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.6.hs(context).clamp(4.0, 6.0)),
                  Text(
                    location.phoneNumber,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
              size: isSelected
                  ? 2.4.hs(context).clamp(20.0, 24.0)
                  : 1.8.hs(context).clamp(16.0, 18.0),
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
