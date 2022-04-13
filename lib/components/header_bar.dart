import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';

class HeaderBarWidget extends StatefulWidget implements PreferredSizeWidget {
  final Channel channel;

  final List<Widget>? actions;

  const HeaderBarWidget({Key? key, required this.channel, this.actions})
      : preferredSize = const Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize; // default is 56.0

  @override
  _HeaderBarWidgetState createState() => _HeaderBarWidgetState();
}

class _HeaderBarWidgetState extends State<HeaderBarWidget> {
  late Timer _pollTimer;
  late Timer _fadeTimer;

  bool _loading = true;
  bool _isOnline = false;
  int _viewers = 0;
  int _followers = 0;

  int _iteration = 0;

  final NumberFormat _formatter = NumberFormat.compact();

  @override
  void initState() {
    super.initState();

    _poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
    _fadeTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => setState(() {
              _iteration++;
            }));
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
    _fadeTimer.cancel();
    _pollTimer.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = Row(children: [
      Text("/${widget.channel.displayName}"),
      if (_isOnline)
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.red, borderRadius: BorderRadius.circular(8)),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text("LIVE",
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium!
                      .copyWith(color: Colors.white))),
        )
      else
        Container()
    ]);
    return Consumer<LayoutModel>(builder: (context, layoutModel, child) {
      if (!layoutModel.isStatsVisible) {
        return AppBar(
          title: title, centerTitle: true, actions: widget.actions
        );
      }
      return AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(bottom: 4), child: title),
              if (_loading)
                Text("...",
                    style: Theme.of(context)
                        .textTheme
                        .subtitle2
                        ?.copyWith(color: Colors.white))
              else if (_iteration % 2 == 0)
                Text(
                    "${_formatter.format(_viewers)} viewers",
                    style: Theme.of(context)
                        .textTheme
                        .subtitle2
                        ?.copyWith(color: Colors.white))
              else if (_iteration % 2 == 1)
                Text("${_formatter.format(_followers)} followers",
                    style: Theme.of(context)
                        .textTheme
                        .subtitle2
                        ?.copyWith(color: Colors.white))
              else
                Container()
            ],
          ),
          actions: widget.actions);
    });
  }
}
