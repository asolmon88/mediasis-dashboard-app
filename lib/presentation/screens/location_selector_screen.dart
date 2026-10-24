import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/presentation/widgets.dart';
import 'package:flutter/material.dart';

class LocationSelectorScreen extends StatelessWidget {
  const LocationSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 4.ws(context),
              vertical: 2.hs(context).clamp(20.0, 32.0),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 92.ws(context).clamp(360.0, 720.0),
              ),
              child: const LocationSelectorPanel(),
            ),
          ),
        ),
      ),
    );
  }
}
