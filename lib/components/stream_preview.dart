import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class StreamPreview extends StatelessWidget {
  const StreamPreview({
    Key? key,
    required this.channelDisplayName,
  }) : super(key: key);

  final String channelDisplayName;

  @override
  Widget build(BuildContext context) {
    final urlString = (Platform.isAndroid)
        ? "http://localhost:8080/assets/twitch-player.html?channel=$channelDisplayName"
        : "https://player.twitch.tv/?channel=$channelDisplayName&parent=chat.rtirl.com&muted=true&quality=160p30";

    return InAppWebView(
      initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
              useShouldOverrideUrlLoading: true,
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              transparentBackground: true),
          android: AndroidInAppWebViewOptions(
            useHybridComposition: true,
          ),
          ios: IOSInAppWebViewOptions(
            allowsInlineMediaPlayback: true,
          )),
      initialUrlRequest: URLRequest(url: Uri.parse(urlString)),
      gestureRecognizers: {
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      shouldOverrideUrlLoading: (controller, action) async {
        // Prevent navigation outside the player
        final url = action.request.url;
        if (url.toString().startsWith("https://player.twitch.tv")) {
          return NavigationActionPolicy.ALLOW;
        }
        return NavigationActionPolicy.CANCEL;
      },
    );
  }
}
