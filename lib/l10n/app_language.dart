import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_strings.dart';

class AppLanguage extends ValueNotifier<String> {
  AppLanguage._() : super('system');
  static final instance = AppLanguage._();
  Future<void> load() async {
    final saved = (await SharedPreferences.getInstance()).getString(
      'app_language',
    );
    value = ['es', 'en'].contains(saved) ? saved! : 'system';
  }

  Future<void> select(String language) async {
    if (!['system', 'es', 'en'].contains(language)) return;
    value = language;
    await (await SharedPreferences.getInstance()).setString(
      'app_language',
      language,
    );
  }

  Locale? get locale => value == 'system' ? null : Locale(value);
}

extension AppTranslation on BuildContext {
  String tr(String source) {
    final selected = AppLanguage.instance.value;
    final language = selected == 'system'
        ? Localizations.localeOf(this).languageCode
        : selected;
    return translateAppString(source, language);
  }
}

// Use only for application-owned copy. Product/customer content stays plain Text.
class LocalizedText extends StatelessWidget {
  const LocalizedText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });
  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) => Text(
    context.tr(data),
    style: style,
    strutStyle: strutStyle,
    textAlign: textAlign,
    textDirection: textDirection,
    locale: locale,
    softWrap: softWrap,
    overflow: overflow,
    textScaler: textScaler,
    maxLines: maxLines,
    semanticsLabel: semanticsLabel == null ? null : context.tr(semanticsLabel!),
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
    selectionColor: selectionColor,
  );
}

class LanguageSettingsCard extends StatelessWidget {
  const LanguageSettingsCard({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ValueListenableBuilder<String>(
          valueListenable: AppLanguage.instance,
          builder: (context, language, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LocalizedText(
                'Idioma de la aplicación',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              LocalizedText(
                'Elige cómo se muestran los textos de esta tablet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _LanguageChoice(
                value: 'system',
                title: 'Usar idioma del dispositivo',
                subtitle: 'Sistema',
                selected: language == 'system',
              ),
              const SizedBox(height: 10),
              _LanguageChoice(
                value: 'es',
                title: 'Español',
                subtitle: 'Español',
                selected: language == 'es',
              ),
              const SizedBox(height: 10),
              _LanguageChoice(
                value: 'en',
                title: 'English',
                subtitle: 'English',
                selected: language == 'en',
              ),
              const SizedBox(height: 16),
              const LocalizedText(
                'El idioma no cambia la moneda ni el idioma del recibo del negocio.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final String value;
  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => AppLanguage.instance.select(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle != title)
                      Text(
                        context.tr(subtitle),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
