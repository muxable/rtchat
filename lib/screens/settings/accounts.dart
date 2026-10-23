import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/auth/twitch.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/channels.dart';

/// The accounts the app is signed in to, at most one per provider, with a
/// button to add one on each provider that has none.
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  // the provider being signed in to, while its sign in flow runs.
  String? _adding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accounts)),
      body: Consumer<AccountsModel>(
        builder: (context, model, child) {
          final accounts = model.accounts;
          final signedIn = {for (final account in accounts) account.provider};
          final missing =
              Providers.all.where((p) => !signedIn.contains(p)).toList();
          return ListView(
            children: [
              for (final account in accounts) _AccountTile(account: account),
              if (accounts.isNotEmpty && missing.isNotEmpty) const Divider(),
              for (final provider in missing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child:
                      _adding == provider
                          ? const Center(child: CircularProgressIndicator())
                          : SignInButton(
                            provider: provider,
                            target: SignInTarget.addAccount,
                            onStart: () => setState(() => _adding = provider),
                            onComplete: () {
                              if (mounted) setState(() => _adding = null);
                            },
                          ),
                ),
              if (accounts.isNotEmpty) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  iconColor: Colors.redAccent,
                  title: Text(l10n.signOutOfAll),
                  onTap:
                      () => _confirm(
                        context,
                        title: l10n.signOutOfAll,
                        content: l10n.signOutConfirmation,
                        onConfirm: model.signOutAll,
                      ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;

  const _AccountTile({required this.account});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final channel = account.channel;
    final provider = providerName(account.provider);
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            backgroundImage: channel.profilePicture,
            // the picture is only decoration, so fall back to the background.
            onBackgroundImageError: (error, stackTrace) {},
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: ProviderIcon(account.provider, size: 18),
          ),
        ],
      ),
      title: Text(channel.displayName),
      subtitle: Text(provider),
      trailing: IconButton(
        icon: const Icon(Icons.logout_outlined),
        tooltip: l10n.signOut,
        onPressed:
            () => _confirm(
              context,
              title: l10n.signOut,
              content: l10n.signOutOfAccount(channel.displayName, provider),
              onConfirm:
                  () => Provider.of<AccountsModel>(
                    context,
                    listen: false,
                  ).signOut(account),
            ),
      ),
    );
  }
}

Future<void> _confirm(
  BuildContext context, {
  required String title,
  required String content,
  required Future<void> Function() onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(l10n.signOut),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await onConfirm();
              navigator.pop();
            },
          ),
        ],
      );
    },
  );
}
