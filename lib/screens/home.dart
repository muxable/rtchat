import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/audio_channel.dart';
import 'package:rtchat/components/auth/twitch.dart';
import 'package:rtchat/components/channel_panel.dart';
import 'package:rtchat/components/chat_panel.dart';
import 'package:rtchat/components/disco.dart';
import 'package:rtchat/components/drawer/end_drawer.dart';
import 'package:rtchat/components/header_bar.dart';
import 'package:rtchat/components/message_input.dart';
import 'package:rtchat/components/notification_panel.dart';
import 'package:rtchat/components/drawer/right_drawer.dart';
import 'package:rtchat/models/activity_feed.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';
import 'package:wakelock/wakelock.dart';

class HomeScreen extends StatefulWidget {
  final bool isDiscoModeEnabled;
  final Channel channel;

  const HomeScreen(
      {required this.isDiscoModeEnabled, required this.channel, Key? key})
      : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  var _minimized = false;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Wakelock.enable();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      // TODO: implement
      // final model = Provider.of<AudioModel>(context, listen: false);
      // if (model.sources.isNotEmpty && !(await AudioChannel.hasPermission())) {
      //   model.showAudioPermissionDialog(context);
      // }
    });
  }

  @override
  void dispose() {
    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutModel>(builder: (context, layoutModel, child) {
      if (MediaQuery.of(context).orientation == Orientation.portrait) {
        // color of the chat background
        // var brightness = MediaQuery.of(context).platformBrightness;
        // bool isDarkMode = brightness == Brightness.dark;
        // Color chathistoryBackground = isDarkMode ? Colors.black : Colors.white;

        // // dragEnd, user release finger
        // bool dragEnd = layoutModel.dragEnd;
        // Widget notifPanel = NotificationPanelWidget(
        //   height: dragEnd
        //       ? layoutModel.panelHeight.clamp(57, 500)
        //       : layoutModel.onDragStartHeight.clamp(57, 500),
        // );
        return Scaffold(
          key: _scaffoldKey,
          drawer: RightDrawer(channel: widget.channel),
          endDrawer: LeftDrawerWidget(channel: widget.channel),
          appBar: HeaderBarWidget(channel: widget.channel, actions: [
            Consumer<ActivityFeedModel>(builder: (context, model, child) {
              if (!model.isEnabled) {
                return Container();
              }
              return IconButton(
                icon: Icon(layoutModel.isShowNotifications
                    ? Icons.notifications
                    : Icons.notifications_outlined),
                tooltip: 'Activity feed',
                onPressed: () {
                  layoutModel.isShowNotifications =
                      !layoutModel.isShowNotifications;
                },
              );
            }),
            IconButton(
              icon: Icon(layoutModel.isShowPreview
                  ? Icons.preview
                  : Icons.preview_outlined),
              tooltip: 'Stream preview',
              onPressed: () {
                layoutModel.isShowPreview = !layoutModel.isShowPreview;
              },
            ),
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Current viewers',
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
          ]),
          body: Container(
            color: Theme.of(context).primaryColor,
            child: SafeArea(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Expanded(
                  child: Column(children: [
                    if (layoutModel.isShowNotifications) ...[
                      NotificationPanelWidget(
                        height: layoutModel.dragEnd
                            ? layoutModel.panelHeight.clamp(57, 500)
                            : layoutModel.onDragStartHeight.clamp(57, 500),
                      ),
                      if (!layoutModel.locked)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: GestureDetector(
                            onVerticalDragStart: (details) {
                              layoutModel.onDragStartHeight =
                                  layoutModel.panelHeight;
                            },
                            onVerticalDragEnd: (details) {
                              layoutModel.dragEnd = true;
                            },
                            onVerticalDragUpdate: (details) {
                              layoutModel.updatePanelHeight(
                                  dy: details.delta.dy);
                            },
                            child: const Center(
                              child: SizedBox(
                                width: 350,
                                child: Icon(Icons.drag_handle_outlined),
                              ),
                            ),
                          ),
                        )
                      else
                        Container()
                    ] else if (layoutModel.isShowPreview)
                      SizedBox(
                          height: 200,
                          child: InAppWebView(
                            initialOptions: InAppWebViewGroupOptions(
                              crossPlatform: InAppWebViewOptions(
                                  javaScriptEnabled: true,
                                  mediaPlaybackRequiresUserGesture: false,
                                  transparentBackground: true),
                            ),
                            initialUrlRequest: URLRequest(
                                url: Uri.parse(
                                    "https://player.twitch.tv/?channel=${widget.channel.displayName}&parent=chat.rtirl.com&muted=true&quality=mobile")),
                            gestureRecognizers: {
                              Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer()),
                            },
                          ))
                    else
                      Container(),
                    Expanded(
                        child: ChatPanelWidget(onScrollback: (scrollback) {})),
                    Consumer<LayoutModel>(
                        builder: (context, layoutModel, child) {
                      if (layoutModel.isInteractionLockable &&
                          layoutModel.locked) {
                        return Container();
                      }
                      return Consumer<UserModel>(
                          builder: (context, userModel, child) {
                        if (!userModel.isSignedIn()) {
                          return Column(children: [
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Flexible(child: Divider()),
                                  Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text("Sign in to send messages",
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
                      });
                    }),
                  ]),
                ),
              ),
            ),
          ),
        );
        // return Stack(
        //   children: [
        //     // notifPanel,
        //     Column(
        //       children: [
        //         SizedBox(
        //           height:
        //               _minimized ? 56 : layoutModel.panelHeight.clamp(56, 500),
        //         ),
        //         Expanded(
        //           child: Container(
        //             // color: chathistoryBackground,
        //             child: DiscoWidget(
        //               isEnabled: widget.isDiscoModeEnabled,
        //               child: ChannelPanelWidget(
        //                 channel: widget.channel,
        //                 onRequestExpand: () {
        //                   setState(() {
        //                     _minimized = !_minimized;
        //                   });
        //                 },
        //                 onScrollback: (isScrolled) {
        //                   setState(() {
        //                     _minimized = isScrolled;
        //                   });
        //                 },
        //                 onResize: (dy) {
        //                   layoutModel.updatePanelHeight(dy: dy);
        //                 },
        //               ),
        //             ),
        //           ),
        //         ),
        //       ],
        //     )
        //   ],
        // );
      } else {
        return Row(children: [
          NotificationPanelWidget(
            width: min(500, max(layoutModel.panelWidth, 300)),
          ),
          GestureDetector(
              child: Container(
                  width: layoutModel.locked ? 0 : 8, color: Colors.grey),
              onHorizontalDragUpdate: (details) {
                layoutModel.updatePanelWidth(dx: details.delta.dx);
              }),
          Expanded(
              child: DiscoWidget(
                  isEnabled: widget.isDiscoModeEnabled,
                  child: ChannelPanelWidget(channel: widget.channel))),
        ]);
      }
    });
  }
}
