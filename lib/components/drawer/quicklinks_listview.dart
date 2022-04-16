import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/quick_links.dart';
import 'package:rtchat/screens/settings/quick_links.dart';
import 'package:url_launcher/url_launcher.dart';

class QuicklinksListView extends StatelessWidget {
  final browser = ChromeSafariBrowser();

  QuicklinksListView({Key? key}) : super(key: key);

  void launchLink(QuickLinkSource source) async {
    final isWebUrl =
        source.url.scheme == 'http' || source.url.scheme == 'https';
    if (isWebUrl) {
      await browser.open(url: source.url);
    } else {
      await launch(source.url.toString());
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
        children: quickLinksModel.sources.reversed.map((source) {
          return ListTile(
            leading: Icon(quickLinksIconsMap[source.icon] ?? Icons.link),
            title: FutureBuilder<String>(
                future: retrieveName(source),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Text("Loading title");
                  }
                  return Text(snapshot.data ?? "");
                }),
            subtitle: Text(source.url.toString()),
            onTap: () => launchLink(source),
          );
        }).toList(),
      );
    });
  }
}
