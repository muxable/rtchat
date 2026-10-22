import 'package:flutter/material.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts/voice_packs.dart';
import 'package:rtchat/screens/settings/tts/labels.dart';
import 'package:rtchat/urls.dart';

/// Lists the voice packs in the catalog, with the languages each speaks,
/// and installs, updates and deletes them.
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

/// One voice pack: its name, size, languages and license, and what can be
/// done with it.
class VoicePackCard extends StatelessWidget {
  final VoicePack pack;

  const VoicePackCard({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.watch<VoicePacksModel>();
    final theme = Theme.of(context);
    final status = model.status(pack.id);
    final installed = model.installed[pack.id];
    final task = model.task(pack.id);
    final error = model.error(pack.id);
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
              l10n.voicePackDetails(pack.speakers.length, formatBytes(size)),
            ),
            Text(
              l10n.voicePackLanguages(languages.length, languages.join(', ')),
            ),
            if (task != null)
              _InstallProgress(task: task)
            else if (error != null)
              Text(
                l10n.voicePackInstallFailed(pack.name),
                style: TextStyle(color: theme.colorScheme.error),
              ),
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
            if (task == null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (installed != null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          MaterialLocalizations.of(context).deleteButtonTooltip,
                        ),
                        onPressed: () => _confirmDelete(context, model, size),
                      ),
                    if (status == VoicePackStatus.upgradeAvailable)
                      FilledButton.icon(
                        icon: const Icon(Icons.upgrade),
                        label: Text(l10n.voicePackUpdate),
                        onPressed: () => model.install(pack),
                      ),
                    if (installed == null)
                      FilledButton.icon(
                        icon: const Icon(Icons.download),
                        label: Text(l10n.voicePackDownload),
                        onPressed: () => model.install(pack),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    VoicePacksModel model,
    int size,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            content: Text(
              l10n.voicePackDeleteConfirm(pack.name, formatBytes(size)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  MaterialLocalizations.of(context).deleteButtonTooltip,
                ),
              ),
            ],
          ),
    );
    if (confirmed ?? false) await model.delete(pack.id);
  }
}

class _InstallProgress extends StatelessWidget {
  final VoicePackInstallTask task;

  const _InstallProgress({required this.task});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.read<VoicePacksModel>();
    final pack = task.pack;
    return StreamBuilder<VoicePackProgress>(
      stream: task.progress,
      initialData: task.latest,
      builder: (context, snapshot) {
        final progress = snapshot.data ?? task.latest;
        final waitsForWifi =
            progress.phase == VoicePackInstallPhase.waiting &&
            model.waitsForWifi(pack.id);
        final isDownloading =
            progress.phase == VoicePackInstallPhase.downloading;
        final label = switch (progress.phase) {
          _ when waitsForWifi => l10n.voicePackWaitingForWifi,
          VoicePackInstallPhase.waiting ||
          VoicePackInstallPhase.downloading => l10n.voicePackDownloading(
            formatBytes(progress.downloadedBytes),
            formatBytes(progress.totalBytes),
          ),
          VoicePackInstallPhase.verifying ||
          VoicePackInstallPhase.done => l10n.voicePackInstalling,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (waitsForWifi) ...[
                  const Icon(Icons.wifi_off, size: 20),
                  const SizedBox(width: 8),
                ],
                Expanded(child: Text(label)),
                IconButton(
                  tooltip: l10n.cancel,
                  icon: const Icon(Icons.close),
                  onPressed: () => model.cancel(pack.id),
                ),
              ],
            ),
            LinearProgressIndicator(
              value: isDownloading ? progress.fraction : null,
              semanticsLabel: pack.name,
              semanticsValue:
                  isDownloading
                      ? '${(progress.fraction * 100).round()}%'
                      : label,
            ),
            if (waitsForWifi)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  icon: const Icon(Icons.signal_cellular_alt),
                  label: Text(l10n.voicePackUseMobileData),
                  onPressed: () => model.installOverMobileData(pack),
                ),
              ),
          ],
        );
      },
    );
  }
}
