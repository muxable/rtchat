import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/channel_search_bottom_sheet.dart';
import 'package:rtchat/components/channel_search_results.dart' as results;
import 'package:rtchat/components/in_chat_channels.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/views.dart';

/// Picks the channels the app opens with.
class DefaultChannelsScreen extends StatelessWidget {
  /// Lets the user add default channels; the channel search sheet unless
  /// overridden.
  final void Function(BuildContext context)? searchChannels;

  /// Finds the channels shown in the search sheet.
  final results.ChannelSearch? search;

  const DefaultChannelsScreen({
    super.key,
    @visibleForTesting this.searchChannels,
    @visibleForTesting this.search,
  });

  void _searchChannels(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, controller) {
              final views = Provider.of<ViewsModel>(context);
              return ChannelSearchBottomSheetWidget(
                controller: controller,
                search: search,
                // like in chat, tapping a result switches to just it and
                // swiping adds it, replacing the one on its provider.
                onChannelSelect: (channel) => views.defaultChannels = [channel],
                onChannelAdd: views.addDefaultChannel,
                channels: views.defaultChannels,
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.defaultChannels)),
      body: Consumer<ViewsModel>(
        builder: (context, views, child) {
          final defaults = views.defaultChannels;
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.defaultChannelsSubtitle),
              ),
              for (final channel in defaults)
                SwipeToRemoveChannelTile(
                  channel: channel,
                  label: l10n.removeChannel,
                  // without picked channels, the user's own channel is shown and
                  // there's nothing to remove.
                  onRemove:
                      views.hasCustomDefaultChannels
                          ? () => views.removeDefaultChannel(channel)
                          : null,
                ),
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.addChannel),
                onTap: () => (searchChannels ?? _searchChannels)(context),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton(
                      onPressed:
                          views.channels.isEmpty ||
                                  listEquals(views.channels, defaults)
                              ? null
                              : views.useCurrentChannelsAsDefault,
                      child: Text(l10n.save),
                    ),
                    TextButton(
                      onPressed: () {
                        views.resetDefaultChannels();
                        Navigator.of(context).maybePop();
                      },
                      child: Text(l10n.resetToMyChannel),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
