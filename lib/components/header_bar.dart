import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/adapters/channels.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';

class _DurationWidget extends StatelessWidget {
  final DateTime from;
  final TextStyle? style;

  const _DurationWidget({Key? key, this.style, required this.from})
      : super(key: key);

  static String formatDuration(Duration d) {
    var seconds = d.inSeconds;
    final days = seconds ~/ Duration.secondsPerDay;
    seconds -= days * Duration.secondsPerDay;
    final hours = seconds ~/ Duration.secondsPerHour;
    seconds -= hours * Duration.secondsPerHour;
    final minutes = seconds ~/ Duration.secondsPerMinute;
    seconds -= minutes * Duration.secondsPerMinute;

    final List<String> tokens = [];
    if (days != 0) {
      tokens.add('${days}d');
    }
    if (tokens.isNotEmpty || hours != 0) {
      tokens.add('${hours}h');
    }
    if (tokens.isNotEmpty || minutes != 0) {
      tokens.add('${minutes}m');
    }
    tokens.add('${seconds}s');

    return tokens.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final diff = now.difference(from);

        return Text('${formatDuration(diff)} up', style: style);
      },
    );
  }
}

class HeaderBarWidget extends StatefulWidget implements PreferredSizeWidget {
  final Channel channel;

  final List<Widget>? actions;
  final void Function(Channel) onChannelSelect;

  const HeaderBarWidget(
      {Key? key,
      required this.channel,
      this.actions,
      required this.onChannelSelect})
      : preferredSize = const Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize; // default is 56.0

  @override
  State<HeaderBarWidget> createState() => _HeaderBarWidgetState();
}

class _HeaderBarWidgetState extends State<HeaderBarWidget> {
  late Timer _fadeTimer;

  var _locked = false;
  var _iteration = 0;

  @override
  void initState() {
    super.initState();

    _fadeTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_locked) {
        return;
      }
      setState(() {
        _iteration++;
      });
    });
  }

  @override
  void dispose() {
    _fadeTimer.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
        title: GestureDetector(
            onTap: () => setState(() => _locked = !_locked),
            child: StreamBuilder<ChannelMetadata?>(
                stream: ChannelsAdapter.instance.forChannel(widget.channel),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text("/${widget.channel.displayName}",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(color: Colors.white),
                              overflow: TextOverflow.fade)),
                      Row(children: [
                        if (_locked)
                          const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(Icons.lock_outline, size: 12)),
                        Consumer<LayoutModel>(
                            builder: (context, layoutModel, child) {
                          final style = Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white);
                          if (data == null) {
                            return Text("...", style: style);
                          }
                          final texts = <Widget>[];
                          if (layoutModel.isStatsVisible) {
                            if (data is TwitchChannelMetadata) {
                              if (data.onlineAt == null) {
                                texts.add(Text(
                                    AppLocalizations.of(context)!
                                        .followerCount(data.followerCount),
                                    style: style));
                              } else {
                                texts.add(Text(
                                    AppLocalizations.of(context)!
                                        .viewerCount(data.viewerCount),
                                    style: style));
                              }
                            }
                          }
                          if (data.onlineAt != null) {
                            texts.add(_DurationWidget(
                                from: data.onlineAt!, style: style));
                          }
                          if (texts.isEmpty) {
                            return Container();
                          }
                          return texts[_iteration % texts.length];
                        }),
                      ]),
                    ],
                  );
                })),
        actions: widget.actions);
  }
}
