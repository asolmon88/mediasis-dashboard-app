import 'package:mediasis_dashboard_app/l10n/app_language.dart';
import 'package:mediasis_dashboard_app/config/display/screen_adapt.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final errorMessage = context.read<AuthCubit>().state.errorMessage;
      if (errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: LocalizedText(errorMessage)));
        context.read<AuthCubit>().clearError();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage.isNotEmpty,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: LocalizedText(state.errorMessage)));

        context.read<AuthCubit>().clearError();
      },
      child: Form(
        key: _formKey,
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 1.hs(context)),
                Image.asset(
                  'lib/assets/mediasis-orders-logo.png',
                  height: 5.hs(context).clamp(64.0, 112.0),
                ),
                SizedBox(height: 3.hs(context)),
                LocalizedText(
                  'Inicia sesión',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.hs(context)),
                LocalizedText(
                  'Accede a tu panel de mediasis Orders.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.hs(context)),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: context.tr('Correo electrónico'),
                    hintText: context.tr('correo@empresa.com'),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Ingresa tu correo.';
                    if (!email.contains('@')) return 'Correo inválido.';
                    return null;
                  },
                ),
                SizedBox(height: 2.hs(context)),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.tr('Contraseña'),
                    hintText: context.tr('Tu contraseña'),
                  ),
                  validator: (value) {
                    if ((value ?? '').isEmpty) return 'Ingresa tu contraseña.';
                    return null;
                  },
                ),
                SizedBox(height: 3.hs(context)),
                SizedBox(
                  height: 6.5.hs(context).clamp(48.0, 56.0),
                  child: FilledButton(
                    onPressed: authState.isLoading
                        ? null
                        : () => _submit(context),
                    child: authState.isLoading
                        ? SizedBox(
                            width: 2.hs(context).clamp(18.0, 20.0),
                            height: 2.hs(context).clamp(18.0, 20.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 0.2.hs(context).clamp(2.0, 3.0),
                            ),
                          )
                        : const LocalizedText('Ingresar'),
                  ),
                ),
                SizedBox(height: 1.hs(context)),
              ],
            );
          },
        ),
      ),
    );
  }
}
