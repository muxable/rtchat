import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/models/views.dart';

/// Picks which of a multi-channel view's channels a message is sent to.
class SendTargetPicker extends StatelessWidget {
  const SendTargetPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ViewsModel, UserModel>(
        builder: (context, views, userModel, child) {
      final postable = views.postableChannels(userModel.userChannel);
      if (postable.length < 2) {
        return const SizedBox();
      }
      final targets = views.sendTargets(userModel.userChannel);
      final isAll = views.sendTarget == ViewsModel.allChannels;
      final l10n = AppLocalizations.of(context)!;
      return PopupMenuButton<String>(
        tooltip: isAll ? l10n.sendToAllChannels : targets.first.displayName,
        initialValue: isAll ? ViewsModel.allChannels : targets.first.toString(),
        onSelected: (target) => views.sendTarget = target,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: ViewsModel.allChannels,
            child: ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: Text(l10n.sendToAllChannels),
            ),
          ),
          for (final channel in postable)
            PopupMenuItem(
              value: channel.toString(),
              child: ListTile(
                leading: ProviderIcon(channel.provider),
                title: Text(channel.displayName),
              ),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: isAll
              ? const Icon(Icons.all_inclusive)
              : ProviderIcon(targets.first.provider),
        ),
      );
    });
  }
}
