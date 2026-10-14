import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/models/views.dart';

/// Toggles which channels of a multi-channel view show their messages.
class ChannelFilterChips extends StatelessWidget {
  const ChannelFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ViewsModel>(builder: (context, views, child) {
      final channels = views.activeView.channels;
      if (channels.length < 2) {
        return const SizedBox();
      }
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          for (final channel in channels)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: ProviderIcon(channel.provider, size: 16),
                label: Text(channel.displayName),
                selected: !views.hiddenChannels.contains(channel),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                onSelected: (selected) =>
                    views.setChannelHidden(channel, !selected),
              ),
            ),
        ]),
      );
    });
  }
}

/// Marks a message with the platform it came from, for views that merge
/// several channels.
class ChannelAttribution extends StatelessWidget {
  final String provider;
  final Widget child;

  const ChannelAttribution(
      {super.key, required this.provider, required this.child});

  @override
  Widget build(BuildContext context) {
    // the icon sits at the trailing edge, on the message's first line: as a
    // placeholder in a line of the message's text style it gets that line's
    // baseline, which the row lines up with the message's first baseline.
    return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: child),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
            child: Text.rich(TextSpan(children: [
              WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: ProviderIcon(provider, size: 12)),
              // a zero width space gives the line the text style's height.
              const TextSpan(text: '\u200b'),
            ])),
          ),
        ]);
  }
}
