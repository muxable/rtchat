import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/views.dart';

/// A channel that's removed by swiping it to the left, or that can't be
/// swiped when [onRemove] is null.
class SwipeToRemoveChannelTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback? onRemove;

  /// Shown behind the tile while it's swiped.
  final String label;

  const SwipeToRemoveChannelTile(
      {super.key,
      required this.channel,
      required this.onRemove,
      required this.label});

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      leading: ProviderIcon(channel.provider),
      title: Text(channel.displayName),
    );
    final onRemove = this.onRemove;
    if (onRemove == null) {
      return tile;
    }
    final colors = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(channel.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onRemove(),
      background: Container(
        color: colors.errorContainer,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.onErrorContainer)),
          ),
          const SizedBox(width: 12),
          Icon(Icons.delete_outline, color: colors.onErrorContainer),
        ]),
      ),
      child: tile,
    );
  }
}

/// The channels in chat, removed by swiping them to the left. Shown only when
/// there are several, as the last channel can't be removed.
class InChatChannels extends StatelessWidget {
  const InChatChannels({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ViewsModel>(builder: (context, views, child) {
      final channels = views.channels;
      if (channels.length < 2) {
        return const SizedBox.shrink();
      }
      final l10n = AppLocalizations.of(context)!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(l10n.inChat,
                style: Theme.of(context).textTheme.titleSmall),
          ),
          for (final channel in channels)
            SwipeToRemoveChannelTile(
              channel: channel,
              label: l10n.removeFromChat,
              onRemove: () => views.removeChannel(channel),
            ),
          const Divider(),
        ],
      );
    });
  }
}
