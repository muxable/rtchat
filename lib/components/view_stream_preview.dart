import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/components/stream_preview.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/views.dart';

/// Previews the stream of the picked channel, with a picker to switch between
/// the channels shown when there are several.
class ViewStreamPreview extends StatelessWidget {
  /// Previewed when no channels are shown.
  final Channel fallback;

  const ViewStreamPreview({super.key, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Consumer<ViewsModel>(
      builder: (context, views, child) {
        final channel = views.previewChannel ?? fallback;
        final channels = views.channels;
        return Stack(
          children: [
            Positioned.fill(child: StreamPreview(channel: channel)),
            if (channels.length > 1)
              Positioned(
                top: 4,
                left: 4,
                child: PopupMenuButton<Channel>(
                  tooltip: channel.displayName,
                  initialValue: channel,
                  onSelected: (selected) => views.previewChannel = selected,
                  itemBuilder:
                      (context) => [
                        for (final option in channels)
                          PopupMenuItem(
                            value: option,
                            child: ListTile(
                              leading: ProviderIcon(option.provider),
                              title: Text(option.displayName),
                            ),
                          ),
                      ],
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ProviderIcon(channel.provider, size: 16),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
