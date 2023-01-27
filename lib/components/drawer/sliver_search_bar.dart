import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SliverSearchBarWidget extends StatelessWidget {
  final void Function(String) onFilterBySearchBarText;

  const SliverSearchBarWidget({Key? key, required this.onFilterBySearchBarText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Center(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                color: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 24.0),
                  Expanded(
                    child: TextField(
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.search,
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      onChanged: (value) async {
                        onFilterBySearchBarText(value);
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.search),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
