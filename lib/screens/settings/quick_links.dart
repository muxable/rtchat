import 'package:flutter/material.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/quick_links.dart';
import 'package:rtchat/screens/settings/dismissible_delete_background.dart';

class QuickLinksScreen extends StatefulWidget {
  const QuickLinksScreen({Key? key}) : super(key: key);

  @override
  _QuickLinksScreenState createState() => _QuickLinksScreenState();
}

class _QuickLinksScreenState extends State<QuickLinksScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textEditingController = TextEditingController();
  String _activeIcon = "view_list";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quick links")),
      body: Column(children: [
        Expanded(child:
            Consumer<QuickLinksModel>(builder: (context, quickLinks, child) {
          return ReorderableListView(
            children: quickLinks.sources.map((source) {
              final name = source.name;
              return Dismissible(
                key: ValueKey(source),
                background: const DismissibleDeleteBackground(),
                child: ListTile(
                  key: ValueKey(source),
                  leading: Text(source.icon,
                      style: const TextStyle(
                          fontSize: 24, fontFamily: "MaterialIcons")),
                  title:
                      name == null ? Text(source.url.toString()) : Text(name),
                  subtitle: name == null ? null : Text(source.url.toString()),
                  trailing: const Icon(Icons.drag_handle),
                ),
                onDismissed: (direction) {
                  quickLinks.removeSource(source);
                },
              );
            }).toList(),
            onReorder: quickLinks.swapSource,
          );
        })),
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Form(
            key: _formKey,
            child: Row(children: [
              PopupMenuButton<String>(
                icon: Text(_activeIcon,
                    style: const TextStyle(
                        fontSize: 24, fontFamily: "MaterialIcons")),
                onSelected: (result) {
                  setState(() {
                    _activeIcon = result;
                  });
                },
                itemBuilder: (context) => [
                  "home",
                  "manage_accounts",
                  "account_balance",
                  "view_list",
                  "code",
                  "analytics",
                  "store",
                  "receipt",
                  "gavel",
                  "rule",
                  "sensors",
                  "speaker_notes",
                  "settings_input_antenna",
                  "settings_input_component",
                  "donut_small",
                  "online_prediction",
                ]
                    .map((icon) => PopupMenuItem(
                        value: icon,
                        child: Text(icon,
                            style: const TextStyle(
                                fontSize: 24, fontFamily: "MaterialIcons"))))
                    .toList(),
              ),
              Expanded(
                child: TextFormField(
                    controller: _textEditingController,
                    decoration: const InputDecoration(hintText: "URL"),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          Uri.tryParse(value) == null) {
                        return "This doesn't look like a valid URL.";
                      }
                      final quickLinksModel =
                          Provider.of<QuickLinksModel>(context, listen: false);
                      if (quickLinksModel.sources.any(
                          (s) => s.url.toString() == Uri.encodeFull(value))) {
                        return "This link already exists";
                      }
                      return null;
                    }),
              ),
              IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // fetch the title for the page.
                      final url = _textEditingController.text;
                      final metadata = await MetadataFetch.extract(url);

                      Provider.of<QuickLinksModel>(context, listen: false)
                          .addSource(QuickLinkSource(
                              metadata?.title, _activeIcon, Uri.parse(url)));
                    }
                  }),
            ]),
          ),
        ),
      ]),
    );
  }
}
