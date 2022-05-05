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
      initialUrlRequest: URLRequest(
          url: Uri.parse(
              "https://player.twitch.tv/?channel=$channelDisplayName&parent=chat.rtirl.com&muted=true&quality=mobile")),
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
