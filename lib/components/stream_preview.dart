import 'dart:async';
import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/stream_preview.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StreamPreview extends StatefulWidget {
  const StreamPreview({Key? key, required this.channel}) : super(key: key);

  final Channel channel;

  @override
  State<StreamPreview> createState() => _StreamPreviewState();
}

class _StreamPreviewState extends State<StreamPreview> {
  WebViewController? _controller;
  String? url;

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(minutes: 1),
          content: const Text(
              "Hey there! Glad you like using stream preview but heads up it uses a lot of battery. Reading chat without it will extend your battery life."),
          action: SnackBarAction(
            label: 'Okay',
            onPressed: () {
              model.showBatteryPrompt = false;
              _promptTimer = null;
            },
          ),
        ));
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    _promptTimer?.cancel();
  }

  @override
  void didUpdateWidget(StreamPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newUrl =
        'https://chat.rtirl.com/embed?provider=${widget.channel.provider}&channelId=${widget.channel.channelId}';
    if (url != newUrl && _controller != null) {
      _controller!.loadUrl(newUrl);
      url = newUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      WebView(
        initialUrl:
            'https://chat.rtirl.com/embed?provider=${widget.channel.provider}&channelId=${widget.channel.channelId}',
        onWebViewCreated: (controller) {
          if (!mounted) {
            return;
          }
          setState(() {
            _controller = controller;
          });
        },
        onPageFinished: (url) async {
          final controller = _controller;
          if (controller == null || !mounted) {
            return;
          }
          final model = Provider.of<StreamPreviewModel>(context, listen: false);
          await controller.runJavascript(
              await rootBundle.loadString('assets/twitch-tunnel.js'));
          // wait a second for twitch to catch up.
          await Future.delayed(const Duration(seconds: 1));
          await _controller?.runJavascript("action(Actions.SetMuted, false)");
          await _controller?.runJavascript(
              "action(Actions.SetVolume, ${model.volume / 100})");
          if (model.isHighDefinition) {
            await _controller
                ?.runJavascript("action(Actions.SetQuality, 'auto')");
          } else {
            await _controller
                ?.runJavascript("action(Actions.SetQuality, '160p')");
          }
        },
        javascriptMode: JavascriptMode.unrestricted,
        allowsInlineMediaPlayback: true,
        initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
        javascriptChannels: {
          JavascriptChannel(
              name: "Flutter",
              onMessageReceived: (message) {
                try {
                  final data = jsonDecode(message.message);
                  if (data is Map && data.containsKey('params')) {
                    final params = data['params'];
                    if (params is Map && mounted) {
                      setState(() => _playerState = params["playback"]);
                    }
                  }
                } catch (e, st) {
                  FirebaseCrashlytics.instance.recordError(e, st);
                }
              })
        },
      ),
      if (_playerState == null || _playerState == "Idle")
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: Text(
                  "Loading (or stream is offline)...",
                  style: TextStyle(color: Colors.white),
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
                color: Colors.black.withOpacity(0.4),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Consumer<StreamPreviewModel>(
                    builder: (context, model, child) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                              onPressed: !_isOverlayActive
                                  ? null
                                  : () async {
                                      if (model.volume == 0) {
                                        model.volume = 100;
                                      } else if (model.volume == 100) {
                                        model.volume = 33;
                                      } else {
                                        model.volume = 0;
                                      }
                                      await _controller?.runJavascript(
                                          "action(Actions.SetMuted, false)");
                                      await _controller?.runJavascript(
                                          "action(Actions.SetVolume, ${model.volume / 100})");
                                    },
                              color: Colors.white,
                              icon: Icon(
                                model.volume == 0
                                    ? Icons.volume_mute
                                    : model.volume == 100
                                        ? Icons.volume_up
                                        : Icons.volume_down,
                              )),
                          IconButton(
                              onPressed: !_isOverlayActive
                                  ? null
                                  : () async {
                                      model.isHighDefinition =
                                          !model.isHighDefinition;
                                      if (model.isHighDefinition) {
                                        await _controller?.runJavascript(
                                            "action(Actions.SetQuality, 'auto')");
                                      } else {
                                        await _controller?.runJavascript(
                                            "action(Actions.SetQuality, '160p')");
                                      }
                                    },
                              color: Colors.white,
                              icon: Icon(model.isHighDefinition
                                  ? Icons.hd
                                  : Icons.sd)),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}
