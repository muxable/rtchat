import 'package:flutter/material.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts/voice_packs.dart';
import 'package:rtchat/screens/settings/tts/labels.dart';
import 'package:rtchat/urls.dart';

/// Lists the voice packs in the catalog, with the languages each speaks,
/// and deletes them.
class VoicePacksScreen extends StatefulWidget {
  const VoicePacksScreen({super.key});

  @override
  State<VoicePacksScreen> createState() => _VoicePacksScreenState();
}

class _VoicePacksScreenState extends State<VoicePacksScreen> {
  @override
  void initState() {
    super.initState();
    context.read<VoicePacksModel>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.watch<VoicePacksModel>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.voicePacks)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.voicePacksDescription),
          ),
          for (final pack in model.packs)
            VoicePackCard(key: ValueKey(pack.id), pack: pack),
        ],
      ),
    );
  }
}

/// One voice pack: its name, size, languages and license, and deleting it.
class VoicePackCard extends StatelessWidget {
  final VoicePack pack;

  const VoicePackCard({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.watch<VoicePacksModel>();
    final theme = Theme.of(context);
    final installed = model.installed[pack.id];
    final size = installed?.sizeOnDisk ?? pack.downloadSize;
    final languages = [
      for (final language in sortLanguages(context, pack.languages))
        languageName(context, language),
    ];
    final license = pack.license;
    final small = theme.textTheme.bodySmall;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(pack.name, style: theme.textTheme.titleMedium),
            Text(
                l10n.voicePackDetails(pack.speakers.length, formatBytes(size))),
            Text(l10n.voicePackLanguages(
                languages.length, languages.join(', '))),
            if (license?.attribution case final attribution?)
              Text(attribution, style: small),
            // OpenRAIL licenses' use restrictions must be passed on.
            if (license != null && license.name.contains('OpenRAIL'))
              Text(l10n.voicePackOpenRailNotice, style: small),
            if (license?.url case final url?)
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(license!.name.replaceFirst('LicenseRef-', '')),
                onPressed: () => openUrl(url),
              ),
            if (installed != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: Text(
                      MaterialLocalizations.of(context).deleteButtonTooltip),
                  onPressed: () => _confirmDelete(context, model, size),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, VoicePacksModel model, int size) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content:
            Text(l10n.voicePackDeleteConfirm(pack.name, formatBytes(size))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(MaterialLocalizations.of(context).deleteButtonTooltip),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await model.delete(pack.id);
  }
}
