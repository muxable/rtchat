import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/activity_feed.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum ActivityFeedType { disabled, standard, custom }

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({Key? key}) : super(key: key);

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  final _textEditingController = TextEditingController();
  WebViewController? _webViewController;
  ActivityFeedModel? _activityFeedModel;
  var _showControls = true;
  final _formKey = GlobalKey<FormState>();

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
    if (url != null && url.isNotEmpty) {
      await _webViewController?.loadUrl(url);
    }
  }

  String? getUri() {
    final activityFeedModel =
        Provider.of<ActivityFeedModel>(context, listen: false);
    final userModel = Provider.of<UserModel>(context, listen: false);
    final channel = userModel.userChannel;
    if (activityFeedModel.isCustom) {
      final uri = Uri.tryParse(activityFeedModel.customUrl);
      if (uri == null) {
        return null;
      }
      return uri.scheme.isEmpty ? 'https://$uri' : uri.toString();
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
    final uri = getUri();
    return Scaffold(
      appBar: _showControls
          ? AppBar(
              title: Text(AppLocalizations.of(context)!.activityFeed),
              actions: [
                IconButton(
                  icon: const Icon(Icons.cookie_outlined),
                  tooltip: AppLocalizations.of(context)!.clearCookies,
                  onPressed: () async {
                    final cookieManager = CookieManager();
                    if (await cookieManager.clearCookies()) {
                      await _webViewController?.reload();
                    }
                  },
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Consumer3<ActivityFeedModel, UserModel, LayoutModel>(builder:
            (context, activityFeedModel, userModel, layoutModel, child) {
          return Column(children: [
            if (_showControls)
              RadioListTile(
                title: Text(AppLocalizations.of(context)!.disabled),
                value: true,
                groupValue: !activityFeedModel.isEnabled,
                onChanged: (value) {
                  activityFeedModel.isEnabled = false;
                  layoutModel.isShowNotifications = false;
                },
              ),
            if (_showControls)
              RadioListTile(
                title: Text(AppLocalizations.of(context)!.twitchActivityFeed),
                subtitle: userModel.isSignedIn()
                    ? null
                    : Text(AppLocalizations.of(context)!.signInToEnable),
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
            if (_showControls)
              RadioListTile(
                title: Form(
                  key: _formKey,
                  child: TextFormField(
                      controller: _textEditingController,
                      decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.customUrl,
                          suffixIcon: IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: () {
                                showModalBottomSheet<void>(
                                    context: context,
                                    builder: (context) {
                                      return MobileScanner(
                                          allowDuplicates: false,
                                          onDetect: (barcode, args) {
                                            final code = barcode.rawValue;
                                            if (code != null) {
                                              _textEditingController.text =
                                                  code;
                                            }
                                            Navigator.of(context).pop();
                                          });
                                    });
                              })),
                      validator: (value) {
                        if (value != null && Uri.tryParse(value) == null) {
                          return AppLocalizations.of(context)!
                              .invalidUrlErrorText;
                        }
                        return null;
                      },
                      onChanged: (value) {
                        activityFeedModel.isEnabled = true;
                        if (Uri.tryParse(value) != null) {
                          activityFeedModel.customUrl = value;
                        }
                        activityFeedModel.isCustom = true;
                        _formKey.currentState?.validate();
                      }),
                ),
                value: true,
                groupValue:
                    activityFeedModel.isEnabled && activityFeedModel.isCustom,
                onChanged: (value) {
                  activityFeedModel.isEnabled = true;
                  activityFeedModel.isCustom = true;
                },
              ),
            GestureDetector(
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                  });
                },
                child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_showControls
                              ? Icons.unfold_more
                              : Icons.unfold_less),
                          Text(AppLocalizations.of(context)!.preview),
                        ]))),
            activityFeedModel.isEnabled
                ? Expanded(
                    child: Padding(
                        padding: _showControls
                            ? const EdgeInsets.all(16)
                            : const EdgeInsets.only(top: 16),
                        child: WebView(
                          initialUrl: uri,
                          javascriptMode: JavascriptMode.unrestricted,
                          initialMediaPlaybackPolicy:
                              AutoMediaPlaybackPolicy.always_allow,
                          allowsInlineMediaPlayback: true,
                          zoomEnabled: false,
                          onWebViewCreated: (controller) =>
                              setState(() => _webViewController = controller),
                          gestureRecognizers: {
                            Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer()),
                          },
                        )),
                  )
                : Container(),
          ]);
        }),
      ),
    );
  }
}
