import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/stream_preview.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class StreamPreview extends StatefulWidget {
  const StreamPreview({super.key, required this.channel});

  final Channel channel;

  @override
  State<StreamPreview> createState() => _StreamPreviewState();
}

extension Embed on Channel {
  Uri get embedUri {
    return Uri.parse(
      'https://chat.rtirl.com/embed?provider=$provider&channelId=$channelId',
    );
  }
}

class _StreamPreviewState extends State<StreamPreview> {
  late WebViewController _controller;
  late Uri url;
  bool _isControllerReady = false;

  var _isOverlayActive = false;
  Timer? _overlayTimer;
  String? _playerState;
  Timer? _promptTimer;

  @override
  void initState() {
    super.initState();

    final model = Provider.of<StreamPreviewModel>(context, listen: false);
    if (model.showBatteryPrompt) {
      _promptTimer = Timer(const Duration(minutes: 5), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(minutes: 1),
            content: Text(AppLocalizations.of(context)!.streamPreviewMessage),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.okay,
              onPressed: () {
                model.showBatteryPrompt = false;
                _promptTimer = null;
              },
            ),
          ),
        );
      });
    }

    url = widget.channel.embedUri;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      _controller = WebViewController.fromPlatformCreationParams(
        WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const {},
        ),
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      _controller = WebViewController.fromPlatformCreationParams(
        AndroidWebViewControllerCreationParams(),
      );
    } else {
      throw UnsupportedError("Unsupported platform");
    }

    unawaited(_initializeController());
  }

  Future<void> _initializeController() async {
    final model = Provider.of<StreamPreviewModel>(context, listen: false);
    if (_controller.platform is AndroidWebViewController) {
      await (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.enableZoom(false);
    await _controller.addJavaScriptChannel(
      "Flutter",
      onMessageReceived: (message) {
        try {
          final data = jsonDecode(message.message);
          if (data is! Map || !mounted) return;
          final params = data['params'];
          if (data['namespace'] == 'twitch-embed' &&
              (data['eventName'] == 'offline' ||
                  data['eventName'] == 'error')) {
            setState(() => _playerState = 'Unavailable');
          } else if (params is Map && params['playback'] is String) {
            final playback = params['playback'] as String;
            // Idle updates must not cover the player's offline/error message.
            if (_playerState != 'Unavailable' || playback != 'Idle') {
              setState(() => _playerState = playback);
            }
          }
        } catch (e, st) {
          FirebaseCrashlytics.instance.recordError(e, st);
        }
      },
    );
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (finishedUrl) async {
          final channelUrl = url;
          // only twitch's player can be driven over the javascript tunnel,
          // and dispose() loads a blank page that has no player at all.
          if (!mounted ||
              !_isTwitch ||
              Uri.tryParse(finishedUrl)?.host != 'player.twitch.tv') {
            return;
          }
          await _runJavaScript(
            await rootBundle.loadString('assets/twitch-tunnel.js'),
          );
          if (!mounted || url != channelUrl) {
            return;
          }
          if (Platform.isIOS) {
            await _runJavaScript(
              "window.action(window.Actions.SetMuted, ${model.volume == 0})",
            );
          } else {
            await _runJavaScript(
              "window.action(window.Actions.SetMuted, false)",
            );
            await _runJavaScript(
              "window.action(window.Actions.SetVolume, ${model.volume / 100})",
            );
            if (model.isHighDefinition) {
              await _runJavaScript(
                "window.action(window.Actions.SetQuality, 'auto')",
              );
            } else {
              await _runJavaScript(
                "window.action(window.Actions.SetQuality, '360p')",
              );
              await Future.delayed(const Duration(seconds: 2));
              if (!mounted || !_isTwitch || url != channelUrl) {
                return;
              }
              await _runJavaScript(
                "window.action(window.Actions.SetQuality, '360p30')",
              );
            }
          }
          // Small mobile previews do not qualify for Twitch autoplay.
          // The tunnel waits until the player is ready before starting it.
          await _runJavaScript("window.action(window.Actions.Play)");
        },
      ),
    );
    _isControllerReady = true;
    if (mounted) {
      await _controller.loadRequest(url);
    }
  }

  @override
  void dispose() {
    super.dispose();

    _promptTimer?.cancel();
    _overlayTimer?.cancel();

    // on iOS, the webview is not disposed when the widget is disposed.
    // this causes audio to keep playing even when the widget is closed.
    // therefore, we load a blank page to silence the audio.
    if (Platform.isIOS) {
      _controller.loadHtmlString(" ");
    }
  }

  @override
  void didUpdateWidget(StreamPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newUrl = widget.channel.embedUri;
    if (url != newUrl) {
      _playerState = null;
      _isOverlayActive = false;
      _overlayTimer?.cancel();
      url = newUrl;
      if (_isControllerReady) {
        _controller.loadRequest(newUrl);
      }
    }
  }

  /// Runs [javaScript] in the player, ignoring failures: the page may not
  /// have loaded the tunnel yet or may have navigated away, and an uncaught
  /// failure would otherwise be reported as a fatal crash.
  Future<void> _runJavaScript(String javaScript) async {
    try {
      await _controller.runJavaScript(javaScript);
    } on PlatformException catch (e) {
      debugPrint('stream preview javascript failed: $e');
    }
  }

  bool get _isTwitch => widget.channel.provider == Providers.twitch;

  @override
  Widget build(BuildContext context) {
    if (!_isTwitch) {
      // other players don't report their state, so they use their own
      // controls rather than our overlay.
      return WebViewWidget(controller: _controller);
    }
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_playerState == null || _playerState == "Idle")
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.streamPreviewLoading,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          )
        else if (_playerState == "Playing")
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _overlayTimer?.cancel();
                _overlayTimer = Timer(const Duration(seconds: 3), () {
                  _overlayTimer = null;
                  if (!mounted) return;
                  setState(() {
                    _isOverlayActive = false;
                  });
                });
                setState(() {
                  _isOverlayActive = true;
                });
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: _isOverlayActive ? 1.0 : 0.0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Consumer<StreamPreviewModel>(
                      builder: (context, model, child) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed:
                                  !_isOverlayActive
                                      ? null
                                      : () async {
                                        if (Platform.isIOS) {
                                          // SetVolume doesn't seem to work on ios so we use SetMuted instead and toggle between 0 and 100.
                                          model.volume =
                                              model.volume == 0 ? 100 : 0;
                                          await _runJavaScript(
                                            "window.action(window.Actions.SetMuted, ${model.volume == 0})",
                                          );
                                          return;
                                        }
                                        if (model.volume == 0) {
                                          model.volume = 100;
                                        } else if (model.volume == 100) {
                                          model.volume = 33;
                                        } else {
                                          model.volume = 0;
                                        }
                                        await _runJavaScript(
                                          "window.action(window.Actions.SetMuted, false)",
                                        );
                                        await _runJavaScript(
                                          "window.action(window.Actions.SetVolume, ${model.volume / 100})",
                                        );
                                      },
                              color: Colors.white,
                              icon: Icon(
                                model.volume == 0
                                    ? Icons.volume_mute
                                    : model.volume == 100
                                    ? Icons.volume_up
                                    : Icons.volume_down,
                              ),
                            ),
                            // SetQuality doesn't seem to work on ios so we don't show the button.
                            if (!Platform.isIOS)
                              IconButton(
                                onPressed:
                                    !_isOverlayActive
                                        ? null
                                        : () async {
                                          final channelUrl = url;
                                          model.isHighDefinition =
                                              !model.isHighDefinition;
                                          if (model.isHighDefinition) {
                                            await _runJavaScript(
                                              "window.action(window.Actions.SetQuality, 'auto')",
                                            );
                                          } else {
                                            await _runJavaScript(
                                              "window.action(window.Actions.SetQuality, '360p')",
                                            );
                                            await Future.delayed(
                                              const Duration(seconds: 2),
                                            );
                                            if (!mounted ||
                                                !_isTwitch ||
                                                url != channelUrl) {
                                              return;
                                            }
                                            await _runJavaScript(
                                              "window.action(window.Actions.SetQuality, '360p30')",
                                            );
                                          }
                                        },
                                color: Colors.white,
                                icon: Icon(
                                  model.isHighDefinition ? Icons.hd : Icons.sd,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
