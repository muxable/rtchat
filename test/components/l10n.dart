import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';

class TestLocalizations extends StatelessWidget {
  final Widget child;
  const TestLocalizations({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Localizations(
      delegates: const [
        ...AppLocalizations.localizationsDelegates,
        LocaleNamesLocalizationsDelegate(),
      ],
      locale: const Locale('en'),
      child: child,
    );
  }
}
