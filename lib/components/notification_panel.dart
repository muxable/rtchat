import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/title_bar.dart';
import 'package:rtchat/models/activity_feed.dart';
import 'package:rtchat/models/user.dart';

class NotificationPanelWidget extends StatefulWidget {
  final double width;
  final double height;
  final double maxHeight;

  const NotificationPanelWidget(
      {Key? key,
      this.width = double.infinity,
      this.height = double.infinity,
      this.maxHeight = double.infinity})
      : super(key: key);

  @override
  _NotificationPanelWidgetState createState() =>
      _NotificationPanelWidgetState();
}

class _NotificationPanelWidgetState extends State<NotificationPanelWidget> {
  ActivityFeedModel? _activityFeedModel;
  InAppWebViewController? _activityFeedController;

  @override
  void initState() {
    super.initState();

    _activityFeedModel = Provider.of<ActivityFeedModel>(context, listen: false);
    _activityFeedModel!.addListener(synchronizeActivityFeedUrl);
  }

  @override
  void dispose() {
    _activityFeedModel?.removeListener(synchronizeActivityFeedUrl);

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
    return AnimatedContainer(
      width: widget.width,
      height: widget.height,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 400),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TitleBarWidget(),
        Expanded(child: Builder(builder: (context) {
          final tabs = TabBarView(
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
                          "https://player.twitch.tv/?channel=${channel.displayName}&parent=chat.rtirl.com&muted=true&quality=mobile")),
                  gestureRecognizers: {
                    Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer()),
                  },
                );
              }),
            ],
          );
          if (widget.height == double.infinity) {
            return tabs;
          }
          return tabs;
          // return ClipRect(
          //   child: OverflowBox(
          //       alignment: Alignment.topCenter,
          //       minHeight: widget.maxHeight,
          //       maxHeight: widget.maxHeight,
          //       child: tabs),
          // );
        })),
      ]),
    );
  }
}
