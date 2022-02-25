import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/settings_button.dart';
import 'package:rtchat/components/statistics_bar.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/quick_links.dart';
import 'package:rtchat/screens/settings/quick_links.dart';
import 'package:url_launcher/url_launcher.dart';

class TitleBarWidget extends StatelessWidget {
  final browser = ChromeSafariBrowser();

  TitleBarWidget({Key? key}) : super(key: key);

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
    final row = Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // tabs
      const SizedBox(
        width: 168,
        child: TabBar(
          tabs: [
            Tab(icon: Icon(Icons.notifications_outlined)),
            Tab(icon: Icon(Icons.preview_outlined)),
          ],
        ),
      ),
      const Spacer(),
      Consumer<ChannelsModel>(builder: (context, channelsModel, child) {
        if (channelsModel.subscribedChannels.isEmpty) {
          return Container();
        }
        final first = channelsModel.subscribedChannels.first;
        return StatisticsBarWidget(
            provider: first.provider, channelId: first.channelId);
      }),
      // quick links
      // Consumer<QuickLinksModel>(builder: (context, quickLinksModel, child) {
      //   return Expanded(
      //       child: ListView(
      //     scrollDirection: Axis.horizontal,
      //     reverse: true,
      //     children: quickLinksModel.sources.reversed.map((source) {
      //       return IconButton(
      //           icon: Icon(quickLinksIconsMap[source.icon] ?? Icons.link),
      //           onPressed: () => launchLink(source));
      //     }).toList(),
      //   ));
      // }),
      // settings button
      // const SettingsButtonWidget(),
    ]);
    return IconTheme(
        data: Theme.of(context).primaryIconTheme,
        child: Container(
            height: 56, color: Theme.of(context).primaryColor, child: row));
  }
}
