import 'package:flutter/material.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
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
    final model = context.read<VoicePacksModel>();
    model.load().then((_) => model.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.watch<VoicePacksModel>();
    final streamLanguage =
        context.watch<TtsModel>().readingLanguage.languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.voicePacks)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(l10n.voicePacksDescription),
          ),
          ListTile(
            leading: const Icon(Icons.sd_storage_outlined),
            title: Text(l10n.voicePacksStorageUsed(
                formatBytes(context, model.storageUsed))),
          ),
          for (final pack in model.packs)
            VoicePackCard(
                key: ValueKey(pack.id),
                pack: pack,
                streamLanguage: streamLanguage),
        ],
      ),
    );
  }
}

/// One voice pack: its name, size, languages and license, and what can be
/// done with it.
class VoicePackCard extends StatelessWidget {
  final VoicePack pack;

  /// The language to list first and mark among the pack's.
  final String streamLanguage;

  const VoicePackCard(
      {super.key, required this.pack, required this.streamLanguage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.watch<VoicePacksModel>();
    final theme = Theme.of(context);
    final installed = model.installed[pack.id];
    final license = pack.license;
    final size = installed?.sizeOnDisk ?? pack.downloadSize;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(pack.name, style: theme.textTheme.titleMedium),
                  if (installed != null)
                    Chip(
                      avatar: const Icon(Icons.check_circle, size: 16),
                      label: Text(l10n.voicePackInstalled),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(l10n.voicePackDetails(
                  pack.speakers.length, formatBytes(context, size))),
            ),
            _Languages(pack: pack, streamLanguage: streamLanguage),
            if (license != null) _License(license: license),
            if (installed != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: Text(
                        MaterialLocalizations.of(context).deleteButtonTooltip),
                    onPressed: () => _confirmDelete(context, model, size),
                  ),
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
    final delete = MaterialLocalizations.of(context).deleteButtonTooltip;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
            l10n.voicePackDeleteConfirm(pack.name, formatBytes(context, size))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(delete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await model.delete(pack.id);
  }
}

/// The languages [pack] speaks: how many and their names, then, expanded,
/// a chip for each, the stream's first.
class _Languages extends StatelessWidget {
  final VoicePack pack;
  final String streamLanguage;

  const _Languages({required this.pack, required this.streamLanguage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stream = LanguageTag.bestMatch(streamLanguage, pack.languages);
    final languages = sortLanguages(context, pack.languages, first: stream);
    final names = [for (final l in languages) languageName(context, l)];
    return Theme(
      // no dividers above and below the expanded list.
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey('languages-${pack.id}'),
        leading: const Icon(Icons.translate),
        title: Text(l10n.voicePackLanguageCount(pack.languages.length)),
        subtitle: Text(names.join(', '),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (i, language) in languages.indexed)
                Chip(
                  avatar: language == stream
                      ? Icon(Icons.live_tv,
                          size: 16, semanticLabel: l10n.streamLanguage)
                      : null,
                  label: Text(names[i]),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The license's attribution, its use restrictions if it's an OpenRAIL
/// license, and a link to it.
class _License extends StatelessWidget {
  final VoicePackLicense license;

  const _License({required this.license});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.bodySmall;
    final url = license.url;
    final attribution = license.attribution;
    final name = license.name.replaceFirst(RegExp('^LicenseRef-'), '');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (attribution != null) Text(attribution, style: style),
          if (name.toLowerCase().contains('openrail')) ...[
            const SizedBox(height: 4),
            Text(l10n.voicePackOpenRailNotice, style: style),
          ],
          if (url != null)
            TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(name),
              onPressed: () => openUrl(url),
            )
          else
            Text(name, style: style),
        ],
      ),
    );
  }
}
