import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/activity_feed.dart';
import 'package:rtchat/models/user.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ActivityFeedPanelWidget extends StatefulWidget {
  const ActivityFeedPanelWidget({Key? key}) : super(key: key);

  @override
  State<ActivityFeedPanelWidget> createState() =>
      _ActivityFeedPanelWidgetState();
}

class _ActivityFeedPanelWidgetState extends State<ActivityFeedPanelWidget> {
  ActivityFeedModel? _activityFeedModel;
  WebViewController? _activityFeedController;

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
    if (uri != null && uri.isNotEmpty) {
      await _activityFeedController?.loadUrl(uri);
    }
  }

  String? getUri() {
    final activityFeedModel =
        Provider.of<ActivityFeedModel>(context, listen: false);
    final userModel = Provider.of<UserModel>(context, listen: false);
    final channel = userModel.userChannel;
    if (activityFeedModel.isCustom) {
      return activityFeedModel.customUrl;
    } else if (channel == null) {
      return null;
    }
    switch (channel.provider) {
      case "twitch":
        return "https://dashboard.twitch.tv/popout/u/${channel.displayName}/stream-manager/activity-feed";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: getUri(),
      javascriptMode: JavascriptMode.unrestricted,
      initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
      allowsInlineMediaPlayback: true,
      zoomEnabled: false,
      onWebViewCreated: (controller) =>
          setState(() => _activityFeedController = controller),
      gestureRecognizers: {
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
    );
  }
}
