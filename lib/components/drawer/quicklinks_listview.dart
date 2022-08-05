import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/quick_links.dart';
import 'package:rtchat/screens/settings/quick_links.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart'
    as flutter_custom_tabs;
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class QuicklinksListView extends StatelessWidget {
  const QuicklinksListView({Key? key}) : super(key: key);

  void launchLink(QuickLinkSource source) async {
    final isWebUrl =
        source.url.scheme == 'http' || source.url.scheme == 'https';
    if (isWebUrl) {
      await flutter_custom_tabs.launch(source.url.toString());
    } else {
      await url_launcher.launchUrl(source.url);
    }
  }

  Future<String> retrieveName(QuickLinkSource link) async {
    final metadata = await MetadataFetch.extract(link.url.toString());
    return metadata?.title ?? link.url.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuickLinksModel>(
        builder: (context, quickLinksModel, child) {
      return Column(
        children: quickLinksModel.sources.map((source) {
          final url = source.url.toString();
          return ListTile(
            leading: Icon(quickLinksIconsMap[source.icon] ?? Icons.link),
            title: Text(source.label),
              subtitle: Text(
                url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            onTap: () => launchLink(source),
            onLongPress: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: url)).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              });
            },
          );
        }).toList(),
      );
    });
  }
}
