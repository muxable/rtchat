import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/audio_channel.dart';
import 'package:rtchat/components/channel_panel.dart';
import 'package:rtchat/components/notification_panel.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/models/layout.dart';
import 'package:wakelock/wakelock.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
      final model = Provider.of<AudioModel>(context, listen: false);
      if (model.sources.isNotEmpty && !(await AudioChannel.hasPermission())) {
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
    final content =
        Consumer<LayoutModel>(builder: (context, layoutModel, child) {
      if (MediaQuery.of(context).orientation == Orientation.portrait) {
        return Column(children: [
          LayoutBuilder(builder: (context, constraints) {
            return NotificationPanelWidget(
              height: _minimized ? 56 : layoutModel.panelHeight.clamp(56, 500),
              maxHeight: layoutModel.panelHeight.clamp(56, 500),
            );
          }),
          Expanded(
              child: ChannelPanelWidget(
            onScrollback: (isScrolled) {
              setState(() {
                _minimized = isScrolled;
              });
            },
            onResize: (dy) {
              layoutModel.updatePanelHeight(dy: dy);
            },
          )),
        ]);
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
          const Expanded(child: ChannelPanelWidget()),
        ]);
      }
    });
    return Scaffold(
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
