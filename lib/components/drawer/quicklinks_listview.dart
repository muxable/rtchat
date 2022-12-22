import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/quick_links.dart';
import 'package:rtchat/screens/settings/quick_links.dart';
import 'package:url_launcher/url_launcher.dart';

class QuicklinksListView extends StatelessWidget {
  const QuicklinksListView({Key? key}) : super(key: key);

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
            onTap: () =>
                launchUrl(source.url, mode: LaunchMode.externalApplication),
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
