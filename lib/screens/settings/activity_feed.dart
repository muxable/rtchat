import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/activity_feed.dart';

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
    // TODO: implement
    // final url = _activityFeedModel?.url;
    // if (url != null && url.toString().isNotEmpty) {
    //   await _inAppWebViewController?.loadUrl(urlRequest: URLRequest(url: url));
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Activity feed")),
      body: Consumer<ActivityFeedModel>(
          builder: (context, activityFeedModel, child) {
        return Column(children: [
          RadioListTile(
            title: const Text('Twitch activity feed'),
            value: false,
            groupValue: activityFeedModel.isCustom,
            onChanged: (value) {
              activityFeedModel.isCustom = false;
            },
          ),
          RadioListTile(
            title: TextField(
                controller: _textEditingController,
                decoration: const InputDecoration(hintText: "Custom URL"),
                onChanged: (value) {
                  activityFeedModel.customUrl = value;
                  activityFeedModel.isCustom = true;
                }),
            value: true,
            groupValue: activityFeedModel.isCustom,
            onChanged: (value) {
              activityFeedModel.isCustom = true;
            },
          ),
          const Padding(
              padding: EdgeInsets.only(top: 16), child: Text("Preview")),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: InAppWebView(
                // TODO: implement
                // initialUrlRequest: activityFeedModel.url != null
                //     ? URLRequest(url: activityFeedModel.url)
                //     : null,
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
