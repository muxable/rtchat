import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/stream_uptime.dart';

class StreamUptimeWidget extends StatefulWidget {
  const StreamUptimeWidget({Key? key}) : super(key: key);

  @override
  State<StreamUptimeWidget> createState() => _StreamUptimeState();
}

class _StreamUptimeState extends State<StreamUptimeWidget> {
  Duration duration = Duration();
  DateTime? startingTimestamp;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    print('set state is called');
    // get the timer of the online event
    final m = Provider.of<StreamUptime>(context, listen: false);
    if (m.isOnline) {
      startingTimestamp = m.streamStartTimestamp;
    }

    // compute the diff
    final diff = DateTime.now().difference(startingTimestamp ?? DateTime.now());
    final seconds = diff.inSeconds;
    duration = Duration(seconds: seconds);
    timer = Timer.periodic(const Duration(seconds: 1), (_) => updateTimer());
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  void updateTimer() {
    setState(() {
      final seconds = duration.inSeconds + 1;
      duration = Duration(seconds: seconds);
    });
  }

  @override
  Widget build(BuildContext context) {
    print('timer is rebuilding');
    // return Consumer<StreamUptime>(
    //   builder: (context, streamUptimeModel, child) {
    //     if (streamUptimeModel.isOnline) {
    //       return Text("${duration.inSeconds}");
    //     } else {
    //       return Text("${duration.inSeconds}");
    //     }
    //   },
    // );
    return Text("time: ${duration.inSeconds}");
  }
}
