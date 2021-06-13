import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/channel_panel.dart';
import 'package:rtchat/components/quick_links_bar.dart';
import 'package:rtchat/components/settings_button.dart';
import 'package:rtchat/components/title_bar.dart';
import 'package:rtchat/models/activity_feed.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';
import 'package:wakelock/wakelock.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  var _minimized = false;
  ActivityFeedModel? _activityFeedModel;
  InAppWebViewController? _activityFeedController;

  @override
  void initState() {
    super.initState();
    Wakelock.enable();

    _activityFeedModel = Provider.of<ActivityFeedModel>(context, listen: false);
    _activityFeedModel!.addListener(synchronizeActivityFeedUrl);
  }

  @override
  void dispose() {
    _activityFeedModel?.removeListener(synchronizeActivityFeedUrl);

    Wakelock.disable();
    super.dispose();
  }

  void synchronizeActivityFeedUrl() async {
    final url = _activityFeedModel?.url;
    if (url != null && url.toString().isNotEmpty) {
      await _activityFeedController?.loadUrl(urlRequest: URLRequest(url: url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: TitleBarWidget(),
          actions: [QuickLinksBar(), SettingsButtonWidget()]),
      body: Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        if (MediaQuery.of(context).orientation == Orientation.portrait) {
          return Column(children: [
            AnimatedContainer(
              height: _minimized
                  ? min(layoutModel.panelHeight, 0)
                  : layoutModel.panelHeight,
              duration: Duration(milliseconds: 500),
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: layoutModel.panelHeight,
                  child: TabBarView(
                    children: [
                      Consumer<ActivityFeedModel>(
                          builder: (context, activityFeedModel, child) {
                        final url = activityFeedModel.url;
                        if (url == null) {
                          return Container();
                        }
                        return InAppWebView(
                          initialOptions: InAppWebViewGroupOptions(
                            crossPlatform: InAppWebViewOptions(
                                javaScriptEnabled: true,
                                mediaPlaybackRequiresUserGesture: false,
                                transparentBackground: true),
                          ),
                          initialUrlRequest: URLRequest(url: url),
                          onWebViewCreated: (controller) =>
                              _activityFeedController = controller,
                          gestureRecognizers: {
                            Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer()),
                          },
                        );
                      }),
                      Consumer<UserModel>(builder: (context, userModel, child) {
                        final channel = userModel.userChannel;
                        if (channel == null) {
                          return Container();
                        }
                        return InAppWebView(
                          initialOptions: InAppWebViewGroupOptions(
                            crossPlatform: InAppWebViewOptions(
                                javaScriptEnabled: true,
                                mediaPlaybackRequiresUserGesture: false,
                                transparentBackground: true),
                          ),
                          initialUrlRequest: URLRequest(
                              url: Uri.parse(
                                  "https://player.twitch.tv/?channel=${channel.displayName}&parent=chat.rtirl.com")),
                          gestureRecognizers: {
                            Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer()),
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
                child: ChannelPanelWidget(
              onScrollback: (isScrolled) {
                setState(() {
                  _minimized = isScrolled;
                });
              },
              onResize: (dy) {
                layoutModel.updatePanelHeight(dy: dy);
              },
            )),
          ]);
        } else {
          return Container();
        }
      }),
    );
  }
}
