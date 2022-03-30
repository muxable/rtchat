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

const quickLinksIconsMap = {
  "home": Icons.home_outlined,
  "manage_accounts": Icons.manage_accounts_outlined,
  "account_balance": Icons.account_balance_outlined,
  "view_list": Icons.view_list_outlined,
  "code": Icons.code_outlined,
  "analytics": Icons.analytics_outlined,
  "store": Icons.store_outlined,
  "receipt": Icons.receipt_outlined,
  "gavel": Icons.gavel_outlined,
  "rule": Icons.rule_outlined,
  "sensors": Icons.sensors_outlined,
  "speaker_notes": Icons.speaker_notes_outlined,
  "settings_input_antenna": Icons.settings_input_antenna_outlined,
  "settings_input_component": Icons.settings_input_component_outlined,
  "donut_small": Icons.donut_small_outlined,
  "online_prediction": Icons.online_prediction_outlined,
  "link": Icons.link_outlined,
};

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
              return Dismissible(
                key: ValueKey(source),
                background: const DismissibleDeleteBackground(),
                child: ListTile(
                  key: ValueKey(source),
                  leading: Icon(quickLinksIconsMap[source.icon] ?? Icons.link),
                  title: FutureBuilder<String>(
                      future: retrieveName(source),
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Text("Loading title");
                        }
                        return Text(snapshot.data!);
                      }),
                  subtitle: Text(source.url.toString()),
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
                icon: Icon(quickLinksIconsMap[_activeIcon] ?? Icons.link),
                onSelected: (result) {
                  setState(() {
                    _activeIcon = result;
                  });
                },
                itemBuilder: (context) {
                  final entries = quickLinksIconsMap.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key));
                  return entries
                      .map((entry) => PopupMenuItem(
                          value: entry.key, child: Icon(entry.value)))
                      .toList();
                },
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
                    },
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: addLink),
              ),
              IconButton(icon: const Icon(Icons.add), onPressed: addLink)
            ]),
          ),
        ),
      ]),
    );
  }

  Future<String> retrieveName(QuickLinkSource link) async {
    final metadata = await MetadataFetch.extract(link.url.toString());
    return metadata?.title ?? link.url.toString();
  }

  void addLink() {
    if (_formKey.currentState!.validate()) {
      Provider.of<QuickLinksModel>(context, listen: false).addSource(
          QuickLinkSource(_activeIcon, Uri.parse(_textEditingController.text)));
      _textEditingController.clear();
      FocusScope.of(context).unfocus();
    }
  }
}
