import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/layout.dart';

class StatisticsBarWidget extends StatefulWidget {
  final String provider;
  final String channelId;

  StatisticsBarWidget(
      {Key? key, required this.provider, required this.channelId})
      : super(key: key);

  @override
  _StatisticsBarWidgetState createState() => _StatisticsBarWidgetState();
}

final getStatistics = FirebaseFunctions.instance.httpsCallable("getStatistics");

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
    _timer = Timer.periodic(Duration(seconds: 15), (_) async {
      await _poll();
    });
  }

  Future<void> _poll() async {
    final statistics = await getStatistics({
      "provider": widget.provider,
      "channelId": widget.channelId,
    });
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _isOnline = statistics.data['isOnline'] ?? false;
      _viewers = statistics.data['viewers'] ?? 0;
      _followers = statistics.data['followers'] ?? 0;
    });
  }

  @override
  void dispose() {
    _timer.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutModel>(builder: (context, layoutModel, child) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Builder(builder: (context) {
          if (_loading) {
            return Container();
          }
          final backgroundColor = _isOnline ? Colors.green : Colors.red;
          if (!layoutModel.isStatsVisible) {
            return Chip(
              backgroundColor: backgroundColor,
              label: _isOnline
                  ? const Text('Stream online')
                  : const Text('Stream offline'),
            );
          }
          return Chip(
            backgroundColor: backgroundColor,
            label: Row(children: [
              Icon(Icons.visibility),
              SizedBox(width: 8),
              Text(_formatter.format(_viewers)),
              SizedBox(width: 8),
              Icon(Icons.people),
              SizedBox(width: 8),
              Text(_formatter.format(_followers)),
            ]),
          );
        }),
      );
    });
  }
}
