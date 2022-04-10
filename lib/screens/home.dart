import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/audio_channel.dart';
import 'package:rtchat/components/channel_panel.dart';
import 'package:rtchat/components/disco.dart';
import 'package:rtchat/components/drawer/end_drawer.dart';
import 'package:rtchat/components/notification_panel.dart';
import 'package:rtchat/components/drawer/right_drawer.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
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
    final content =
        Consumer<LayoutModel>(builder: (context, layoutModel, child) {
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
        return Stack(
          children: [
            // notifPanel,
            Column(
              children: [
                SizedBox(
                  height:
                      _minimized ? 56 : layoutModel.panelHeight.clamp(56, 500),
                ),
                Expanded(
                  child: Container(
                    // color: chathistoryBackground,
                    child: DiscoWidget(
                      isEnabled: widget.isDiscoModeEnabled,
                      child: ChannelPanelWidget(
                        channel: widget.channel,
                        onRequestExpand: () {
                          setState(() {
                            _minimized = !_minimized;
                          });
                        },
                        onScrollback: (isScrolled) {
                          setState(() {
                            _minimized = isScrolled;
                          });
                        },
                        onResize: (dy) {
                          layoutModel.updatePanelHeight(dy: dy);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        );
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
    return Scaffold(
      // drawer: const RightDrawer(),
      // endDrawer: const LeftDrawerWidget(),
      appBar: AppBar(
        title: Text("test"),
      ),
      body: Container(
        color: Theme.of(context).primaryColor,
        child: SafeArea(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: content,
          ),
        ),
      ),
    );
  }
}
