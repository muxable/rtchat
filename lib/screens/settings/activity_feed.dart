import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/activity_feed.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

enum ActivityFeedType { disabled, standard, custom }

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  final _textEditingController = TextEditingController();
  late final WebViewController _controller;
  var _showControls = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _textEditingController.text =
        Provider.of<ActivityFeedModel>(context, listen: false).customUrl;

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
  }

  @override
  void dispose() {
    _textEditingController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showControls
          ? AppBar(
              title: Text(AppLocalizations.of(context)!.activityFeed),
              actions: [
                IconButton(
                  icon: const Icon(Icons.cookie_outlined),
                  tooltip: AppLocalizations.of(context)!.clearCookies,
                  onPressed: () async {
                    final cookieManager = WebViewCookieManager();
                    if (await cookieManager.clearCookies()) {
                      _controller.reload();
                    }
                  },
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Consumer3<ActivityFeedModel, UserModel, LayoutModel>(builder:
            (context, activityFeedModel, userModel, layoutModel, child) {
          Uri? uri;

          final channel = userModel.userChannel;
          if (activityFeedModel.isCustom) {
            final tryUri = Uri.tryParse(activityFeedModel.customUrl);
            if (tryUri != null) {
              uri = tryUri.scheme.isEmpty
                  ? Uri.tryParse("https://$tryUri")
                  : tryUri;
            }
          } else if (channel != null) {
            switch (channel.provider) {
              case "twitch":
                uri = Uri.tryParse(
                    "https://dashboard.twitch.tv/popout/u/${channel.displayName}/stream-manager/activity-feed");
            }
          }

          if (uri != null) {
            _controller.loadRequest(uri);
          } else {
            _controller.loadHtmlString(" ");
          }

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
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final result = await BarcodeScanner.scan(
                                  options: ScanOptions(strings: {
                                    "cancel":
                                        AppLocalizations.of(context)!.cancel,
                                    "flash_on":
                                        AppLocalizations.of(context)!.flashOn,
                                    "flash_off":
                                        AppLocalizations.of(context)!.flashOff,
                                  }),
                                );
                                switch (result.type) {
                                  case ResultType.Barcode:
                                    _textEditingController.text =
                                        result.rawContent;
                                    break;
                                  case ResultType.Cancelled:
                                    break;
                                  case ResultType.Error:
                                    messenger.showSnackBar(SnackBar(
                                        content: Text(result.rawContent)));
                                    break;
                                }
                              }),
                          errorText:
                              Uri.tryParse(activityFeedModel.customUrl) == null
                                  ? "That's not a valid URL"
                                  : null),
                      validator: (value) {
                        if (value != null && Uri.tryParse(value) == null) {
                          return AppLocalizations.of(context)!
                              .invalidUrlErrorText;
                        }
                        return null;
                      },
                      onChanged: (value) {
                        activityFeedModel.isEnabled =
                            Uri.tryParse(value) != null;
                        activityFeedModel.customUrl = value;
                        activityFeedModel.isCustom = true;
                        _formKey.currentState?.validate();
                      }),
                ),
                value: true,
                groupValue:
                    activityFeedModel.isEnabled && activityFeedModel.isCustom,
                onChanged: (value) {
                  final uri = Uri.tryParse(activityFeedModel.customUrl);
                  activityFeedModel.isEnabled = uri != null;
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
                        child: WebViewWidget(
                          controller: _controller,
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
