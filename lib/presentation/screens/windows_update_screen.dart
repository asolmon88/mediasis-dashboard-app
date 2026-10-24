import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WindowsUpdateScreen extends StatelessWidget {
  const WindowsUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cardWidth = 92.ws(context).clamp(340.0, 520.0);
    final state = context.watch<WindowsUpdateCubit>().state;
    final isDownloading = state.status == WindowsUpdateStatus.downloading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 4.ws(context),
              vertical: 4.hs(context),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    2.8.ws(context).clamp(24.0, 28.0),
                  ),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 2.8.ws(context).clamp(24.0, 28.0),
                      offset: Offset(0, 1.4.hs(context).clamp(12.0, 14.0)),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(2.8.ws(context).clamp(22.0, 28.0)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'lib/assets/mediasis-orders-logo.png',
                        height: 4.4.hs(context).clamp(40.0, 44.0),
                      ),
                      SizedBox(height: 2.6.hs(context).clamp(20.0, 28.0)),
                      LocalizedText(
                        'Actualizacion requerida',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 1.hs(context).clamp(8.0, 12.0)),
                      LocalizedText(
                        'Necesitas instalar una nueva version de Mediasis Orders para continuar usando la app en Windows.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 2.2.hs(context).clamp(18.0, 24.0)),
                      _VersionRow(
                        label: 'Version actual',
                        value: state.currentVersion,
                      ),
                      SizedBox(height: 1.hs(context).clamp(8.0, 10.0)),
                      _VersionRow(
                        label: 'Version requerida',
                        value: state.minimumSupportedVersion,
                      ),
                      if (state.latestVersion.isNotEmpty) ...[
                        SizedBox(height: 1.hs(context).clamp(8.0, 10.0)),
                        _VersionRow(
                          label: 'Version publicada',
                          value: state.latestVersion,
                        ),
                      ],
                      if ((state.manifest?.notes ?? '').isNotEmpty) ...[
                        SizedBox(height: 2.2.hs(context).clamp(18.0, 24.0)),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(
                              1.8.ws(context).clamp(16.0, 18.0),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                              1.6.ws(context).clamp(14.0, 16.0),
                            ),
                            child: Text(
                              state.manifest!.notes,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                      if (isDownloading) ...[
                        SizedBox(height: 2.2.hs(context).clamp(18.0, 24.0)),
                        LinearProgressIndicator(
                          value: state.progress <= 0 ? null : state.progress,
                          minHeight: 0.8.hs(context).clamp(6.0, 8.0),
                          borderRadius: BorderRadius.circular(
                            2.hs(context).clamp(12.0, 999.0),
                          ),
                        ),
                        SizedBox(height: 1.hs(context).clamp(8.0, 10.0)),
                        Text(
                          state.progress <= 0
                              ? 'Preparando descarga...'
                              : 'Descargando ${(state.progress * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      if (state.errorMessage.isNotEmpty) ...[
                        SizedBox(height: 2.2.hs(context).clamp(18.0, 24.0)),
                        LocalizedText(
                          state.errorMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                      SizedBox(height: 2.6.hs(context).clamp(20.0, 28.0)),
                      FilledButton.icon(
                        onPressed: isDownloading
                            ? null
                            : () => context
                                  .read<WindowsUpdateCubit>()
                                  .startUpdate(),
                        icon: Icon(
                          Icons.system_update_alt_rounded,
                          size: 1.8.hs(context).clamp(16.0, 18.0),
                        ),
                        label: Text(
                          isDownloading
                              ? 'Actualizando...'
                              : 'Actualizar ahora',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value.isEmpty ? '-' : value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
