import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/quick_links.dart';
import 'package:rtchat/screens/settings/quick_links.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickLinksBar extends StatelessWidget {
  final ChromeSafariBrowser browser = ChromeSafariBrowser();

  QuickLinksBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<QuickLinksModel>(
        builder: (context, quickLinksModel, child) {
      return Expanded(
          child: ListView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        children: quickLinksModel.sources.reversed.map((source) {
          return IconButton(
              icon: Icon(quickLinksIconsMap[source.icon] ?? Icons.link),
              tooltip: source.name,
              onPressed: () => launchLink(source));
        }).toList(),
      ));
    });
  }

  void launchLink(QuickLinkSource source) async {
    final isWebUrl =
        source.url.scheme == 'http' || source.url.scheme == 'https';
    if (isWebUrl) {
      await browser.open(url: source.url);
    } else {
      await launch(
        source.url.toString(),
      );
    }
  }
}
