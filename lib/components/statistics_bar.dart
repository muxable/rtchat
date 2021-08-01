import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';

class StatisticsBarWidget extends StatefulWidget {
  final String provider;
  final String channelId;

  const StatisticsBarWidget(
      {Key? key, required this.provider, required this.channelId})
      : super(key: key);

  @override
  _StatisticsBarWidgetState createState() => _StatisticsBarWidgetState();
}

class _StatisticsBarWidgetState extends State<StatisticsBarWidget> {
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
  void didUpdateWidget(StatisticsBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.provider != widget.provider ||
        oldWidget.channelId != widget.channelId) {
      setState(() => _loading = true);
      _poll();
    }
  }

  Future<void> _poll() async {
    try {
      final statistics = await getStreamMetadata(
          provider: widget.provider, channelId: widget.channelId);
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Builder(builder: (context) {
        final backgroundColor = _loading
            ? Colors.grey
            : _isOnline
                ? Colors.green
                : Colors.red;
        return Align(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: backgroundColor,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child:
                  Consumer<LayoutModel>(builder: (context, layoutModel, child) {
                if (_loading) {
                  return const SizedBox(
                    child: CircularProgressIndicator.adaptive(
                      semanticsLabel: 'Linear progress indicator',
                    ),
                    height: 16,
                    width: 16,
                  );
                }
                if (!layoutModel.isStatsVisible) {
                  return _isOnline
                      ? const Text('Stream online')
                      : const Text('Stream offline');
                }
                return Row(children: [
                  const Icon(Icons.visibility),
                  const SizedBox(width: 8),
                  Text(_formatter.format(_viewers)),
                  const SizedBox(width: 8),
                  const Icon(Icons.people),
                  const SizedBox(width: 8),
                  Text(_formatter.format(_followers)),
                ]);
              }),
            ),
          ),
        );
      }),
    );
  }
}
