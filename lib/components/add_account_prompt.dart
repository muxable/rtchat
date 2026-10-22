import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/auth/twitch.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';

/// Offers a signed-in user to add accounts on the providers they have none
/// on, e.g. "Also stream on Kick?", until it's dismissed.
class AddAccountPrompt extends StatefulWidget {
  const AddAccountPrompt({super.key});

  @override
  State<AddAccountPrompt> createState() => _AddAccountPromptState();
}

class _AddAccountPromptState extends State<AddAccountPrompt> {
  // the provider being signed in to, while its sign in flow runs.
  String? _adding;

  String _prompt(AppLocalizations l10n, List<String> missing) {
    final names = missing.map(providerName).toList();
    if (names.length == 1) {
      return l10n.addAccountPrompt(names.single);
    }
    return l10n.addAccountsPrompt(
      names.sublist(0, names.length - 1).join(', '),
      names.last,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserModel, LayoutModel>(
      builder: (context, userModel, layoutModel, child) {
        if (layoutModel.isAddAccountPromptDismissed ||
            userModel.isLoading ||
            !userModel.isSignedIn()) {
          return const SizedBox.shrink();
        }
        final signedIn = {
          for (final account in userModel.accounts) account.provider,
        };
        final missing =
            Providers.all.where((p) => !signedIn.contains(p)).toList();
        if (missing.isEmpty) {
          return const SizedBox.shrink();
        }
        final l10n = AppLocalizations.of(context)!;
        return MaterialBanner(
          leading: ProviderIcon(missing.first),
          content: Text(_prompt(l10n, missing)),
          actions: [
            TextButton(
              child: Text(l10n.notNow),
              onPressed: () => layoutModel.isAddAccountPromptDismissed = true,
            ),
            for (final provider in missing)
              _adding == provider
                  ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(),
                    ),
                  )
                  : SignInButton(
                    provider: provider,
                    target: SignInTarget.addAccount,
                    onStart: () => setState(() => _adding = provider),
                    onComplete: () {
                      if (mounted) setState(() => _adding = null);
                    },
                  ),
          ],
        );
      },
    );
  }
}
