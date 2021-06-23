import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/quick_links.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickLinksBar extends StatelessWidget {
  final ChromeSafariBrowser browser = new ChromeSafariBrowser();

  @override
  Widget build(BuildContext context) {
    return Consumer<QuickLinksModel>(
        builder: (context, quickLinksModel, child) {
      return Row(
          children: quickLinksModel.sources.map((source) {
        return IconButton(
            icon: Text(source.icon,
                style: TextStyle(fontSize: 24, fontFamily: "MaterialIcons")),
            tooltip: source.name,
            onPressed: () async => launchLink(source));
      }).toList());
    });
  }

  void launchLink(QuickLinkSource source) async {
    final bool isWebUrl =
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
