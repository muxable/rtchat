import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/header_search_bar.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';

class LanguagesScreen extends StatefulWidget {
  const LanguagesScreen({Key? key}) : super(key: key);

  @override
  State<LanguagesScreen> createState() => LanguagesScreenState();
}

class LanguagesScreenState extends State<LanguagesScreen> {
  var _isSearching = false;
  late final HeaderSearchBar searchBarWidget;
  List<String> languages = [];
  List<String> filteredLanguages = [];
  Widget animatedHeader = const Align(
    alignment: Alignment.centerLeft,
    child: Text('Languages'),
  );

  Future<List<String>> filterList(
      List<String> list, String searchBarText) async {
    return list
        .where((String element) => Language(element)
            .displayName(context)
            .toLowerCase()
            .contains(searchBarText.toLowerCase()))
        .toList();
  }

  void onFilteredByText(String searchBarText) {
    if (searchBarText.isEmpty) {
      setState(() {
        filteredLanguages = languages;
      });
    } else {
      Future.wait([
        filterList(languages, searchBarText)
            .then((value) => filteredLanguages = value),
      ]);
      setState(() {
        filteredLanguages = filteredLanguages;
      });
    }
  }

  @override
  void initState() {
    languages.addAll(supportedLanguages);
    filteredLanguages.addAll(supportedLanguages);
    searchBarWidget = HeaderSearchBar(
      onFilterBySearchBarText: onFilteredByText,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: animatedHeader,
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (_isSearching) {
                  animatedHeader = searchBarWidget;
                } else {
                  filteredLanguages = languages;
                  animatedHeader = const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Languages',
                    ),
                  );
                }
              });
            },
            icon: !_isSearching
                ? const Icon(Icons.search)
                : const Icon(Icons.close),
            tooltip: !_isSearching ? 'Search languages' : 'Close search',
          )
        ],
      ),
      body: SafeArea(
        child: Consumer<TtsModel>(
          builder: (context, model, child) {
            return ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                final language = Language(filteredLanguages[index]);
                return ListTile(
                  title: Text(language.displayName(context)),
                  onTap: () {
                    model.language = language;
                    Navigator.pop(context);
                  },
                );
              },
              itemCount: filteredLanguages.length,
            );
          },
        ),
      ),
    );
  }
}
