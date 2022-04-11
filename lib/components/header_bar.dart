import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';

class HeaderBarWidget extends StatefulWidget implements PreferredSizeWidget {
  final Channel channel;

  const HeaderBarWidget({Key? key, required this.channel})
      : preferredSize = const Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize; // default is 56.0

  @override
  _HeaderBarWidgetState createState() => _HeaderBarWidgetState();
}

class _HeaderBarWidgetState extends State<HeaderBarWidget> {
  late Timer _timer;

  bool _loading = true;
  bool _isOnline = false;
  int _viewers = 0;
  int _followers = 0;

  final NumberFormat _formatter = NumberFormat.compact();

  @override
  void initState() {
    super.initState();

    _poll();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
  }

  @override
  void didUpdateWidget(HeaderBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.channel != widget.channel) {
      setState(() => _loading = true);
      _poll();
    }
  }

  Future<void> _poll() async {
    try {
      final statistics = await getStreamMetadata(
          provider: widget.channel.provider,
          channelId: widget.channel.channelId);
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _isOnline = statistics.isOnline;
        if (statistics is TwitchStreamMetadata) {
          _viewers = statistics.viewerCount;
          _followers = statistics.followerCount;
        }
      });
    } catch (e) {
      return;
    }
  }

  @override
  void dispose() {
    _timer.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutModel>(builder: (context, layoutModel, child) {
      if (!layoutModel.isStatsVisible) {
        return AppBar(
          title: Text("/${widget.channel.displayName}"),
          centerTitle: true,
        );
      }
      if (_loading) {
        return AppBar(
          title: Column(children: [
            Text("/${widget.channel.displayName}"),
            const Text("..."),
          ]),
          centerTitle: true,
        );
      }
      return AppBar(
        title: Column(children: [
          Text("/${widget.channel.displayName}"),
          Text(
              "${_formatter.format(_viewers)} viewers, ${_formatter.format(_followers)} followers"),
        ]),
        centerTitle: true,
      );
    });
  }
}
