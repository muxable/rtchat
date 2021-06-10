import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/quick_links.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickLinksBar extends StatelessWidget {
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
            onPressed: () async {
              await launch(source.url.toString());
            });
      }).toList());
    });
  }
}
