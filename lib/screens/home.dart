import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';
import 'package:rtchat/audio_channel.dart';
import 'package:rtchat/components/activity_feed_panel.dart';
import 'package:rtchat/components/auth/twitch.dart';
import 'package:rtchat/components/chat_panel.dart';
import 'package:rtchat/components/disco.dart';
import 'package:rtchat/components/drawer/end_drawer.dart';
import 'package:rtchat/components/drawer/sidebar.dart';
import 'package:rtchat/components/header_bar.dart';
import 'package:rtchat/components/message_input.dart';
import 'package:rtchat/components/stream_preview.dart';
import 'package:rtchat/eager_drag_recognizer.dart';
import 'package:rtchat/main.dart';
import 'package:rtchat/models/activity_feed.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/tts_plugin.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class ResizableWidget extends StatefulWidget {
  final bool resizable;
  final double height;
  final double width;
  final Function(double) onResizeHeight;
  final Function(double) onResizeWidth;
  final Widget child;

  const ResizableWidget(
      {super.key,
      required this.resizable,
      required this.height,
      required this.width,
      required this.onResizeHeight,
      required this.onResizeWidth,
      required this.child});

  @override
  State<ResizableWidget> createState() => _ResizableWidgetState();
}

class _ResizableWidgetState extends State<ResizableWidget> {
  double _height = 0;
  double _width = 0;

  @override
  void initState() {
    super.initState();
    _height = widget.height;
    _width = widget.width;
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.portrait) {
      return Column(children: [
        SizedBox(
          height: _height.clamp(
              57, math.max(57, MediaQuery.of(context).size.height - 300)),
          child: widget.child,
        ),
        if (widget.resizable)
          GestureDetector(
            onVerticalDragStart: (details) {
              setState(() {
                _height = widget.height;
              });
            },
            onVerticalDragEnd: (details) {
              widget.onResizeHeight(_height.clamp(
                  57, math.max(57, MediaQuery.of(context).size.height - 300)));
            },
            onVerticalDragUpdate: (details) {
              setState(() {
                _height += details.delta.dy;
              });
            },
            child: const SizedBox(
              width: double.infinity,
              height: 30,
              child: Center(
                child: Icon(Icons.drag_handle_outlined),
              ),
            ),
          )
        else
          Container(),
      ]);
    } else {
      return Row(children: [
        SizedBox(
          width: _width.clamp(
              57, math.max(57, MediaQuery.of(context).size.width - 400)),
          child: widget.child,
        ),
        if (widget.resizable)
          RawGestureDetector(
            gestures: {
              EagerHorizontalDragRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                      EagerHorizontalDragRecognizer>(
                () => EagerHorizontalDragRecognizer()
                  ..onStart = (details) {
                    setState(() {
                      _width = widget.width;
                    });
                  }
                  ..onEnd = (details) {
                    widget.onResizeWidth(
                      _width.clamp(
                          57,
                          math.max(
                              57, MediaQuery.of(context).size.width - 400)),
                    );
                  }
                  ..onUpdate = (details) {
                    setState(() {
                      _width += details.delta.dx;
                    });
                  },
                (instance) {},
              )
            },
            child: const SizedBox(
              height: double.infinity,
              width: 30,
              child: Center(
                child: Icon(Icons.drag_indicator),
              ),
            ),
          )
        else
          Container(),
      ]);
    }
  }
}

class HomeScreen extends StatefulWidget {
  final bool isDiscoModeEnabled;
  final Channel channel;
  final void Function(Channel) onChannelSelect;

  const HomeScreen(
      {required this.isDiscoModeEnabled,
      required this.channel,
      required this.onChannelSelect,
      super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Wakelock.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final model = Provider.of<AudioModel>(context, listen: false);
      if (model.sources.isEmpty || (await AudioChannel.hasPermission())) {
        return;
      }
      if (mounted) {
        model.showAudioPermissionDialog(context);
      }
    });
  }

  @override
  void dispose() {
    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;

    return GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Consumer<UserModel>(builder: (context, userModel, child) {
          return Scaffold(
            key: _scaffoldKey,
            drawer: Sidebar(channel: widget.channel),
            endDrawer: userModel.isSignedIn()
                ? EndDrawerWidget(
                    channel: widget.channel,
                  )
                : null,
            drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.6,
            onDrawerChanged: (isOpened) =>
                FocusManager.instance.primaryFocus?.unfocus(),
            onEndDrawerChanged: (isOpened) =>
                FocusManager.instance.primaryFocus?.unfocus(),
            appBar: HeaderBarWidget(
                onChannelSelect: widget.onChannelSelect,
                channel: widget.channel,
                actions: [
                  Consumer2<ActivityFeedModel, LayoutModel>(builder:
                      (context, activityFeedModel, layoutModel, child) {
                    if (!activityFeedModel.isEnabled) {
                      return Container();
                    }
                    return IconButton(
                      icon: Icon(layoutModel.isShowNotifications
                          ? Icons.notifications
                          : Icons.notifications_outlined),
                      tooltip: AppLocalizations.of(context)!.activityFeed,
                      onPressed: () {
                        layoutModel.isShowNotifications =
                            !layoutModel.isShowNotifications;
                      },
                    );
                  }),
                  Consumer<LayoutModel>(builder: (context, layoutModel, child) {
                    return IconButton(
                      icon: Icon(layoutModel.isShowPreview
                          ? Icons.preview
                          : Icons.preview_outlined),
                      tooltip: AppLocalizations.of(context)!.streamPreview,
                      onPressed: () {
                        layoutModel.isShowPreview = !layoutModel.isShowPreview;
                      },
                    );
                  }),
                  Consumer<TtsModel>(
                    builder: (context, ttsModel, child) {
                      return IconButton(
                        icon: Icon(ttsModel.enabled
                            ? Icons.record_voice_over
                            : Icons.voice_over_off),
                        tooltip: AppLocalizations.of(context)!.textToSpeech,
                        onPressed: () async {
                          setState(() {
                            ttsModel.enabled = !ttsModel.enabled;
                          });
                          if (!ttsModel.enabled) {
                            updateChannelSubscription("");
                            await TextToSpeechPlugin.speak(
                                "Text to speech disabled");
                            AwesomeNotifications().dismiss(6853027);
                          } else {
                            channelStreamController.stream
                                .listen((currentChannel) {
                              if (currentChannel.isEmpty) {
                                setState(() {
                                  ttsModel.enabled = false;
                                });
                              }
                            });
                            await TextToSpeechPlugin.speak(
                                "Text to speech enabled");
                            updateChannelSubscription(
                                "${userModel.activeChannel?.provider}:${userModel.activeChannel?.channelId}");
                            AwesomeNotifications().createNotification(
                              content: NotificationContent(
                                id: 6853027,
                                channelKey: 'tts_notifications_key',
                                title: 'Text-to-speech is enabled',
                                body: null,
                                locked: true,
                                autoDismissible: false,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                  if (userModel.isSignedIn())
                    IconButton(
                      icon: const Icon(Icons.people),
                      tooltip: AppLocalizations.of(context)!.currentViewers,
                      onPressed: () {
                        _scaffoldKey.currentState?.openEndDrawer();
                      },
                    ),
                ]),
            body: Container(
              height: MediaQuery.of(context).size.height,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: Builder(builder: (context) {
                  final chatPanelFooter = Consumer<LayoutModel>(
                    builder: (context, layoutModel, child) {
                      return layoutModel.locked ? Container() : child!;
                    },
                    child: Builder(
                      builder: (context) {
                        if (!userModel.isSignedIn()) {
                          return Column(children: [
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Flexible(child: Divider()),
                                  Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                          AppLocalizations.of(context)!
                                              .signInToSendMessages,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge)),
                                  const Flexible(child: Divider()),
                                ]),
                            const SignInWithTwitch(),
                          ]);
                        }

                        return MessageInputWidget(
                          channel: widget.channel,
                        );
                      },
                    ),
                  );
                  if (orientation == Orientation.portrait) {
                    return Consumer<LayoutModel>(
                        builder: (context, layoutModel, child) {
                      return Column(
                          verticalDirection: VerticalDirection.up,
                          children: [
                            // reversed direction because of verticalDirection: VerticalDirection.up
                            chatPanelFooter,

                            Expanded(
                                child: DiscoWidget(
                                    isEnabled: widget.isDiscoModeEnabled,
                                    child: ChatPanelWidget(
                                        channel: widget.channel))),

                            Consumer<LayoutModel>(
                                builder: (context, layoutModel, child) {
                              if (layoutModel.isShowNotifications) {
                                return ResizableWidget(
                                    resizable: !layoutModel.locked,
                                    height: layoutModel.panelHeight,
                                    width: layoutModel.panelWidth,
                                    onResizeHeight: (height) {
                                      layoutModel.panelHeight = height;
                                    },
                                    onResizeWidth: (width) {
                                      layoutModel.panelWidth = width;
                                    },
                                    child: const ActivityFeedPanelWidget());
                              } else if (layoutModel.isShowPreview) {
                                return AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child:
                                        StreamPreview(channel: widget.channel));
                              } else {
                                return Container();
                              }
                            }),
                          ]);
                    });
                  } else {
                    // landscape
                    return Row(children: [
                      Consumer<LayoutModel>(
                          builder: (context, layoutModel, child) {
                        if (!layoutModel.isShowNotifications &&
                            !layoutModel.isShowPreview) {
                          return Container();
                        }
                        return ResizableWidget(
                            resizable: !layoutModel.locked,
                            height: layoutModel.panelHeight,
                            width: layoutModel.panelWidth,
                            onResizeHeight: (height) {
                              layoutModel.panelHeight = height;
                            },
                            onResizeWidth: (width) {
                              layoutModel.panelWidth = width;
                            },
                            child: Consumer<LayoutModel>(
                                builder: (context, layoutModel, child) {
                              if (layoutModel.isShowNotifications) {
                                return const ActivityFeedPanelWidget();
                              } else if (layoutModel.isShowPreview) {
                                return StreamPreview(channel: widget.channel);
                              } else {
                                return Container();
                              }
                            }));
                      }),
                      Expanded(
                          child: Column(children: [
                        Expanded(
                            child: DiscoWidget(
                                isEnabled: widget.isDiscoModeEnabled,
                                child:
                                    ChatPanelWidget(channel: widget.channel))),
                        chatPanelFooter,
                      ]))
                    ]);
                  }
                }),
              ),
            ),
          );
        }));
  }
}
