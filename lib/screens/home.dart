import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/audio_channel.dart';
import 'package:rtchat/components/channel_panel.dart';
import 'package:rtchat/components/disco.dart';
import 'package:rtchat/components/notification_panel.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/models/layout.dart';
import 'package:wakelock/wakelock.dart';

class HomeScreen extends StatefulWidget {
  final bool isDiscoModeEnabled;

  const HomeScreen({required this.isDiscoModeEnabled, Key? key})
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
          KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
            return NotificationPanelWidget(
              height: _minimized || isKeyboardVisible
                  ? 56
                  : layoutModel.panelHeight.clamp(56, 500),
              maxHeight: layoutModel.panelHeight.clamp(56, 500),
            );
          }),
          Expanded(
              child: DiscoWidget(
                  isEnabled: widget.isDiscoModeEnabled,
                  child: ChannelPanelWidget(
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
                  ))),
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
          Expanded(
              child: DiscoWidget(
                  isEnabled: widget.isDiscoModeEnabled,
                  child: const ChannelPanelWidget())),
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
