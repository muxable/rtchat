import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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

  @override
  Widget build(BuildContext context) {
    return Consumer<QuickLinksModel>(
        builder: (context, quickLinksModel, child) {
      if (quickLinksModel.sources.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text("Add quicklinks in setting"),
          ),
        );
      }
      return SizedBox(
        height: 300,
        child: ListView(
          shrinkWrap: true,
          physics: const ScrollPhysics(),
          padding: EdgeInsets.zero,
          children: quickLinksModel.sources.reversed.map((source) {
            return ListTile(
              leading: Icon(quickLinksIconsMap[source.icon] ?? Icons.link),
              title: Text(source.toString()),
              onTap: () => launchLink(source),
            );
          }).toList(),
        ),
      );
    });
  }
}
