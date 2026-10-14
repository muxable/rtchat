import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/views.dart';

/// The channels in chat, each with a button to remove it. Shown only when
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
            ListTile(
              leading: ProviderIcon(channel.provider),
              title: Text(channel.displayName),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.removeFromChat,
                onPressed: () => views.removeChannel(channel),
              ),
            ),
          const Divider(),
        ],
      );
    });
  }
}
