import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/channel_search_bottom_sheet.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';

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

        return Text('${formatDuration(diff)} uptime', style: style);
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
  late Timer _pollTimer;
  late Timer _fadeTimer;

  bool _loading = true;
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
    return AppBar(
        title: GestureDetector(
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  return DraggableScrollableSheet(
                      initialChildSize: 0.8,
                      maxChildSize: 0.9,
                      expand: false,
                      builder: (context, controller) {
                        return Consumer<UserModel>(
                            builder: (context, value, child) {
                          return ChannelSearchBottomSheetWidget(
                              onChannelSelect: widget.onChannelSelect,
                              onRaid: value.userChannel == widget.channel
                                  ? (channel) {
                                      ActionsAdapter.instance.send(
                                          widget.channel,
                                          "/raid ${channel.displayName}");
                                    }
                                  : null,
                              controller: controller);
                        });
                      });
                },
              );
            },
            child: StreamBuilder<DateTime?>(
                stream:
                    MessagesAdapter.instance.forChannelUptime(widget.channel),
                builder: (context, snapshot) {
                  final onlineAt = snapshot.data;

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
                      Consumer<LayoutModel>(
                          builder: (context, layoutModel, child) {
                        final style = Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white);
                        if (_loading) {
                          return Text("...", style: style);
                        }
                        final texts = <Widget>[];
                        if (layoutModel.isStatsVisible) {
                          texts.add(Text(
                              "${_formatter.format(_followers)} followers",
                              style: style));
                        }
                        if (onlineAt != null) {
                          if (layoutModel.isStatsVisible) {
                            texts.add(Text(
                                "${_formatter.format(_viewers)} viewers",
                                style: style));
                          }
                          texts.add(
                              _DurationWidget(from: onlineAt, style: style));
                        }
                        if (texts.isEmpty) {
                          return Container();
                        }
                        return texts[_iteration % texts.length];
                      }),
                    ],
                  );
                })),
        actions: widget.actions);
  }
}
