import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/activity_feed.dart';

enum ActivityFeedType { disabled, standard, custom }

class ActivityFeedScreen extends StatefulWidget {
  @override
  _ActivityFeedScreenState createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  final _textEditingController = TextEditingController();
  InAppWebViewController? _inAppWebViewController;

  @override
  void initState() {
    super.initState();

    final activityFeed = Provider.of<ActivityFeedModel>(context, listen: false);
    _textEditingController.text = activityFeed.customUrl;
    activityFeed.addListener(() {
      if (!activityFeed.isEnabled) {
        _inAppWebViewController?.loadUrl(
            urlRequest: URLRequest(url: Uri.parse("about:blank")));
        return;
      }
      final url = activityFeed.url;
      if (url != null) {
        _inAppWebViewController?.loadUrl(urlRequest: URLRequest(url: url));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Activity feed")),
      body: Consumer<ActivityFeedModel>(
          builder: (context, activityFeedModel, child) {
        var type = ActivityFeedType.disabled;
        if (activityFeedModel.isEnabled) {
          if (activityFeedModel.isCustom) {
            type = ActivityFeedType.custom;
          } else {
            type = ActivityFeedType.standard;
          }
        }
        return Column(children: [
          RadioListTile<ActivityFeedType>(
            title: const Text('Disabled'),
            value: ActivityFeedType.disabled,
            groupValue: type,
            onChanged: (value) {
              activityFeedModel.isEnabled = false;
            },
          ),
          RadioListTile<ActivityFeedType>(
            title: const Text('Twitch activity feed'),
            value: ActivityFeedType.standard,
            groupValue: type,
            onChanged: (value) {
              activityFeedModel.isEnabled = true;
              activityFeedModel.isCustom = false;
            },
          ),
          RadioListTile<ActivityFeedType>(
            title: TextField(
                controller: _textEditingController,
                decoration: InputDecoration(hintText: "Custom URL"),
                onChanged: (value) {
                  activityFeedModel.customUrl = value;
                  activityFeedModel.isEnabled = true;
                  activityFeedModel.isCustom = true;
                }),
            value: ActivityFeedType.custom,
            groupValue: type,
            onChanged: (value) {
              activityFeedModel.isEnabled = true;
              activityFeedModel.isCustom = true;
            },
          ),
          Padding(padding: EdgeInsets.only(top: 16), child: Text("Preview")),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: InAppWebView(
                initialUrlRequest: activityFeedModel.url != null
                    ? URLRequest(url: activityFeedModel.url)
                    : null,
                onWebViewCreated: (controller) =>
                    _inAppWebViewController = controller,
                initialOptions: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                  javaScriptEnabled: true,
                  transparentBackground: true,
                )),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}
