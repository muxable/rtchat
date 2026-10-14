import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/adapters/channels.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/views.dart';

class _DurationWidget extends StatelessWidget {
  final DateTime from;
  final TextStyle? style;

  const _DurationWidget({this.style, required this.from});

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

  /// Where each channel's metadata comes from; Firestore unless overridden.
  final Stream<ChannelMetadata> Function(Channel)? metadataFor;

  const HeaderBarWidget(
      {super.key,
      required this.channel,
      this.actions,
      required this.onChannelSelect,
      @visibleForTesting this.metadataFor})
      : preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  final Size preferredSize; // default is 56.0

  @override
  State<HeaderBarWidget> createState() => _HeaderBarWidgetState();
}

class _HeaderBarWidgetState extends State<HeaderBarWidget> {
  late Timer _fadeTimer;

  // the header rebuilds every few seconds, so keep the metadata stream rather
  // than resubscribing on every build.
  List<Channel> _streamChannels = const [];
  Stream<List<ChannelMetadata?>>? _stream;

  Stream<List<ChannelMetadata?>> _metadata(List<Channel> channels) {
    if (_stream == null || !listEquals(channels, _streamChannels)) {
      _streamChannels = channels;
      final metadataFor =
          widget.metadataFor ?? ChannelsAdapter.instance.forChannel;
      _stream = combineLatest(channels.map(metadataFor).toList());
    }
    return _stream!;
  }

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
    final shown = Provider.of<ViewsModel>(context).channels;
    final channels = shown.length > 1 ? shown : [widget.channel];
    final title = headerTitle(channels);
    final stream = _metadata(channels);
    return AppBar(
        title: GestureDetector(
            onTap: () => setState(() => _locked = !_locked),
            // keyed by the stream so changing the channels drops the previous
            // metadata, which is for a different number of channels.
            child: StreamBuilder<List<ChannelMetadata?>>(
                key: ObjectKey(stream),
                stream: stream,
                builder: (context, snapshot) {
                  final metadata = snapshot.data;
                  final data =
                      metadata == null ? null : aggregateMetadata(metadata);
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [
                              Flexible(
                                child: Text(title,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    overflow: TextOverflow.fade),
                              ),
                              // a live indicator per channel.
                              if (channels.length > 1)
                                for (var i = 0; i < channels.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Tooltip(
                                      message: channels[i].displayName,
                                      child: Icon(Icons.circle,
                                          size: 8,
                                          color: metadata?[i]?.onlineAt != null
                                              ? Colors.red
                                              : Theme.of(context)
                                                  .disabledColor),
                                    ),
                                  ),
                            ])),
                        Consumer<LayoutModel>(
                            builder: (context, layoutModel, child) {
                          final style = Theme.of(context).textTheme.bodyMedium;
                          if (data == null) {
                            return Text("...", style: style);
                          }
                          final texts = <Widget>[];
                          if (layoutModel.isStatsVisible) {
                            if (data is StreamChannelMetadata) {
                              final followerCount = data.followerCount;
                              if (data.onlineAt == null) {
                                if (followerCount != null) {
                                  texts.add(Text(
                                      AppLocalizations.of(context)!
                                          .followerCount(followerCount),
                                      style: style));
                                }
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
                          return Row(children: [
                            if (_locked)
                              const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.lock_outline, size: 12)),
                            Expanded(
                              child: texts[_iteration % texts.length],
                            )
                          ]);
                        }),
                      ]);
                })),
        actions: widget.actions);
  }
}

/// Emits the latest value of every stream (null until a stream has emitted)
/// each time one of them emits.
Stream<List<T?>> combineLatest<T>(List<Stream<T>> streams) {
  final latest = List<T?>.filled(streams.length, null);
  final subscriptions = <StreamSubscription<T>>[];
  late StreamController<List<T?>> controller;
  controller = StreamController<List<T?>>.broadcast(
    onListen: () {
      for (var i = 0; i < streams.length; i++) {
        subscriptions.add(streams[i].listen((value) {
          latest[i] = value;
          controller.add(List.of(latest));
        }, onError: controller.addError));
      }
    },
    onCancel: () {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
      subscriptions.clear();
    },
  );
  return controller.stream;
}

/// Combines the metadata of the channels shown: viewers add up, followers add
/// up when every channel reports them, and they're live from when the first
/// channel went live.
@visibleForTesting
ChannelMetadata aggregateMetadata(List<ChannelMetadata?> metadata) {
  if (metadata.length == 1) {
    return metadata.single ?? ChannelMetadata(onlineAt: null);
  }
  final onlineAts =
      metadata.map((m) => m?.onlineAt).whereType<DateTime>().toList()..sort();
  final streams = metadata.whereType<StreamChannelMetadata>().toList();
  final followers = streams.map((m) => m.followerCount).toList();
  return StreamChannelMetadata(
    onlineAt: onlineAts.firstOrNull,
    viewerCount: streams.fold(0, (sum, m) => sum + m.viewerCount),
    followerCount:
        streams.length == metadata.length && !followers.contains(null)
            ? followers.fold<int>(0, (sum, count) => sum + count!)
            : null,
  );
}

/// The first channel's name, and how many more channels are shown.
@visibleForTesting
String headerTitle(List<Channel> channels) {
  final title = "/${channels.first.displayName}";
  return channels.length > 1 ? "$title +${channels.length - 1}" : title;
}
