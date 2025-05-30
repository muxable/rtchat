import 'package:flutter/material.dart';

import './l10n/app_localizations.dart';

class HeaderSearchBar extends StatelessWidget {
  final void Function(String) onFilterBySearchBarText;

  const HeaderSearchBar({super.key, required this.onFilterBySearchBarText});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        color: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: TextField(
          textInputAction: TextInputAction.search,
          autofocus: true,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.search,
            isDense: true,
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          onChanged: (value) async {
            onFilterBySearchBarText(value);
          },
        ),
      ),
    );
  }
}
