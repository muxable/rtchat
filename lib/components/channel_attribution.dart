import 'package:flutter/material.dart';
import 'package:rtchat/components/provider_icon.dart';

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
