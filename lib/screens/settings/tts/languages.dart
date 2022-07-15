import 'package:flutter/material.dart';
import 'package:rtchat/components/header_search_bar.dart';

class LanguagesScreen extends StatefulWidget {
  const LanguagesScreen({Key? key}) : super(key: key);

  @override
  State<LanguagesScreen> createState() => LanguagesScreenState();
}

class LanguagesScreenState extends State<LanguagesScreen> {
  var _isSearching = false;
  Widget animatedHeader = const Align(
    alignment: Alignment.centerLeft,
    child: Text('Languages'),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  animatedHeader = const HeaderSearchBar();
                } else {
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
      body: ListView(
        children: [
          ListTile(
            title: const Text('English'),
            subtitle: const Text('US'),
            onTap: () {},
          )
        ],
      ),
    );
  }
}
