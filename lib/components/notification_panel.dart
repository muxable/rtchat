import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
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
    final uri = getUri();
    if (uri != null && uri.toString().isNotEmpty) {
      await _activityFeedController?.loadUrl(urlRequest: URLRequest(url: uri));
    }
  }

  Uri? getUri() {
    final activityFeedModel =
        Provider.of<ActivityFeedModel>(context, listen: false);
    final userModel = Provider.of<UserModel>(context, listen: false);
    final channel = userModel.userChannel;
    if (activityFeedModel.isCustom) {
      return Uri.tryParse(activityFeedModel.customUrl);
    } else if (channel == null) {
      return null;
    }
    switch (channel.provider) {
      case "twitch":
        return Uri.tryParse(
            "https://dashboard.twitch.tv/popout/u/${channel.displayName}/stream-manager/activity-feed");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: widget.width,
      height: widget.height,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 400),
      child: InAppWebView(
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              transparentBackground: true),
        ),
        initialUrlRequest: URLRequest(url: getUri()),
        onWebViewCreated: (controller) => _activityFeedController = controller,
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
      ),
    );
  }
}
