import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthenticatedAppBar extends StatelessWidget {
  const AuthenticatedAppBar({required this.toolbarHeight, super.key});

  final double toolbarHeight;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final horizontalSpacing = 3.5.ws(context).clamp(12.0, 28.0);
    final logoHeight = 3.2.hs(context).clamp(21.0, 28.0);
    final actionIconSize = 2.2.hs(context).clamp(18.0, 22.0);
    final isPhoneLayout = isCompactWindow(context);
    final signOut = authState.isLoading
        ? null
        : () async {
            await context.read<PushNotificationsCubit>().disableBeforeSignOut();
            if (!context.mounted) return;
            await context.read<AuthCubit>().signOut();
          };

    return AppBar(
      toolbarHeight: toolbarHeight,
      leadingWidth: isPhoneLayout ? 112 : 156,
      leading: Padding(
        padding: EdgeInsets.only(left: horizontalSpacing),
        child: Image.asset(
          'lib/assets/mediasis-orders-logo.png',
          height: logoHeight,
          alignment: Alignment.centerLeft,
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      actions: [
        Padding(
          padding: EdgeInsets.only(right: horizontalSpacing),
          child: isPhoneLayout
              ? IconButton(
                  onPressed: signOut,
                  icon: Icon(Icons.logout, size: actionIconSize),
                  color: Theme.of(context).colorScheme.primary,
                  tooltip: context.tr('Cerrar sesion'),
                )
              : TextButton.icon(
                  onPressed: signOut,
                  icon: Icon(Icons.logout, size: actionIconSize),
                  label: const LocalizedText('Cerrar sesion'),
                ),
        ),
      ],
    );
  }
}
