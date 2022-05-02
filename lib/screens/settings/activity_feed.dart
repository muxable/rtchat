import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/activity_feed.dart';
import 'package:rtchat/models/user.dart';

enum ActivityFeedType { disabled, standard, custom }

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({Key? key}) : super(key: key);

  @override
  _ActivityFeedScreenState createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  final _textEditingController = TextEditingController();
  InAppWebViewController? _inAppWebViewController;
  ActivityFeedModel? _activityFeedModel;

  @override
  void initState() {
    super.initState();

    _activityFeedModel = Provider.of<ActivityFeedModel>(context, listen: false);
    _textEditingController.text = _activityFeedModel!.customUrl;
    _activityFeedModel!.addListener(synchronizeUrl);
  }

  @override
  void dispose() {
    _activityFeedModel?.removeListener(synchronizeUrl);

    super.dispose();
  }

  void synchronizeUrl() async {
    final url = getUri();
    if (url != null && url.toString().isNotEmpty) {
      await _inAppWebViewController?.loadUrl(urlRequest: URLRequest(url: url));
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
    return Scaffold(
      appBar: AppBar(title: const Text("Activity feed")),
      body: Consumer2<ActivityFeedModel, UserModel>(
          builder: (context, activityFeedModel, userModel, child) {
        return Column(children: [
          RadioListTile(
            title: const Text('Disabled'),
            value: true,
            groupValue: !activityFeedModel.isEnabled,
            onChanged: (value) {
              activityFeedModel.isEnabled = false;
            },
          ),
          RadioListTile(
            title: const Text('Twitch activity feed'),
            subtitle:
                userModel.isSignedIn() ? null : const Text("Must be signed in"),
            value: true,
            groupValue:
                activityFeedModel.isEnabled && !activityFeedModel.isCustom,
            onChanged: userModel.isSignedIn()
                ? (value) {
                    activityFeedModel.isEnabled = true;
                    activityFeedModel.isCustom = false;
                  }
                : null,
          ),
          RadioListTile(
            title: TextField(
                controller: _textEditingController,
                decoration: const InputDecoration(hintText: "Custom URL"),
                onChanged: (value) {
                  activityFeedModel.isEnabled = true;
                  activityFeedModel.customUrl = value;
                  activityFeedModel.isCustom = true;
                }),
            value: true,
            groupValue:
                activityFeedModel.isEnabled && activityFeedModel.isCustom,
            onChanged: (value) {
              activityFeedModel.isEnabled = true;
              activityFeedModel.isCustom = true;
            },
          ),
          const Padding(
              padding: EdgeInsets.only(top: 16), child: Text("Preview")),
          activityFeedModel.isEnabled
              ? Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: InAppWebView(
                      initialUrlRequest: URLRequest(url: getUri()),
                      onWebViewCreated: (controller) =>
                          _inAppWebViewController = controller,
                      initialOptions: InAppWebViewGroupOptions(
                          crossPlatform: InAppWebViewOptions(
                        javaScriptEnabled: true,
                        transparentBackground: true,
                      )),
                    ),
                  ),
                )
              : Container(),
        ]);
      }),
    );
  }
}
