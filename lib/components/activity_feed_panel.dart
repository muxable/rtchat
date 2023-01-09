import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/activity_feed.dart';
import 'package:rtchat/models/user.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class ActivityFeedPanelWidget extends StatefulWidget {
  const ActivityFeedPanelWidget({Key? key}) : super(key: key);

  @override
  State<ActivityFeedPanelWidget> createState() =>
      _ActivityFeedPanelWidgetState();
}

class _ActivityFeedPanelWidgetState extends State<ActivityFeedPanelWidget> {
  late final ActivityFeedModel _activityFeedModel;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _activityFeedModel = Provider.of<ActivityFeedModel>(context, listen: false);
    _activityFeedModel.addListener(synchronizeActivityFeedUrl);

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      _controller = WebViewController.fromPlatformCreationParams(
          WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const {},
      ));
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      _controller = WebViewController.fromPlatformCreationParams(
          AndroidWebViewControllerCreationParams());
    } else {
      throw UnsupportedError("Unsupported platform");
    }

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false);

    synchronizeActivityFeedUrl();
  }

  @override
  void dispose() {
    _activityFeedModel.removeListener(synchronizeActivityFeedUrl);

    super.dispose();
  }

  void synchronizeActivityFeedUrl() async {
    final uri = getUri();
    if (uri != null) {
      await _controller.loadRequest(uri);
    }
  }

  Uri? getUri() {
    final activityFeedModel =
        Provider.of<ActivityFeedModel>(context, listen: false);
    final userModel = Provider.of<UserModel>(context, listen: false);
    final channel = userModel.userChannel;
    if (activityFeedModel.isCustom) {
      final tryUri = Uri.tryParse(activityFeedModel.customUrl);
      if (tryUri != null && !tryUri.hasScheme) {
        return Uri.tryParse("https://${activityFeedModel.customUrl}");
      }
      return tryUri;
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
    return WebViewWidget(
      controller: _controller,
      gestureRecognizers: {
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
    );
  }
}
