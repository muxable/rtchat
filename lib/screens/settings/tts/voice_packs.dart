import 'package:flutter/material.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
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
    final model = context.read<VoicePacksModel>();
    model.load().then((_) => model.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.watch<VoicePacksModel>();
    final Widget body;
    if (!model.isLoaded) {
      body = const Center(child: CircularProgressIndicator());
    } else if (model.loadError != null && model.packs.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l10n.voicePacksLoadError, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed: model.refresh, child: Text(l10n.voicePackRetry)),
          ]),
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(l10n.voicePacksDescription),
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            subtitle: Text(l10n.voicePackMachineGenerated),
          ),
          ListTile(
            leading: const Icon(Icons.sd_storage_outlined),
            title: Text(l10n.voicePacksStorageUsed(
                formatBytes(context, model.storageUsed))),
          ),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.signal_cellular_alt),
            title: Text(l10n.voicePacksAllowMobileData),
            subtitle: Text(l10n.voicePacksAllowMobileDataSubtitle),
            value: model.allowMobileData,
            onChanged: (value) => model.allowMobileData = value,
          ),
          const Divider(),
          for (final pack in model.packs)
            VoicePackCard(
              key: ValueKey(pack.id),
              pack: pack,
              highlightLanguage:
                  context.watch<TtsModel>().readingLanguage.languageCode,
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.voicePacks)),
      body: body,
    );
  }
}

/// A line on a [VoicePackCard] about why its voices can't be used.
class _Note extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Note({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.tertiary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// One voice pack: its name, size, languages and license, and what can be
/// done with it.
class VoicePackCard extends StatelessWidget {
  final VoicePack pack;

  /// The language to mark among the pack's, e.g. the stream's.
  final String? highlightLanguage;

  const VoicePackCard({super.key, required this.pack, this.highlightLanguage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.watch<VoicePacksModel>();
    final theme = Theme.of(context);
    final status = model.status(pack.id);
    final installed = model.installed[pack.id];
    final task = model.task(pack.id);
    final error = model.error(pack.id);
    final license = pack.license;
    final isInstalled = status == VoicePackStatus.installed ||
        status == VoicePackStatus.upgradeAvailable;

    final details = [
      l10n.voicePackVoiceCount(pack.speakers.length),
      l10n.voicePackDownloadSize(formatBytes(context, pack.downloadSize)),
      if (installed != null)
        l10n.voicePackSizeOnDisk(formatBytes(context, installed.sizeOnDisk)),
    ].join(' · ');

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
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(pack.name,
                      style: theme.textTheme.titleMedium,
                      semanticsLabel: pack.name),
                  if (isInstalled)
                    _StatusChip(
                      icon: status == VoicePackStatus.upgradeAvailable
                          ? Icons.upgrade
                          : Icons.check_circle,
                      label: status == VoicePackStatus.upgradeAvailable
                          ? l10n.voicePackUpgradeAvailable
                          : l10n.voicePackInstalled,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(details, style: theme.textTheme.bodyMedium),
            ),
            VoicePackLanguages(
                pack: pack, highlightLanguage: highlightLanguage),
            switch (context.watch<TtsModel>().neuralFallback) {
              NeuralTtsFallback.lowMemoryDevice =>
                _Note(icon: Icons.memory, text: l10n.voicePackLowMemory),
              NeuralTtsFallback.loadFailed when installed != null => _Note(
                  icon: Icons.warning_amber, text: l10n.voicePackLoadFailed),
              _ => const SizedBox.shrink(),
            },
            if (task != null)
              _InstallProgress(pack: pack, task: task)
            else if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.voicePackInstallFailed(
                            pack.name, installErrorReason(context, error)),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            if (license != null)
              _LicenseDetails(license: license, packName: pack.name),
            if (task == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isInstalled)
                      Semantics(
                        container: true,
                        button: true,
                        label: l10n.voicePackDeleteLabel(pack.name),
                        excludeSemantics: true,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l10n.voicePackDelete),
                          onPressed: () => _confirmDelete(context, model),
                        ),
                      ),
                    if (status == VoicePackStatus.upgradeAvailable)
                      FilledButton.icon(
                        icon: const Icon(Icons.upgrade),
                        label: Text(l10n.voicePackUpdate),
                        onPressed: () => model.install(pack),
                      ),
                    if (status == VoicePackStatus.notInstalled)
                      Semantics(
                        container: true,
                        button: true,
                        label: l10n.voicePackDownloadLabel(pack.name),
                        excludeSemantics: true,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.download),
                          label: Text(error == null
                              ? l10n.voicePackDownload
                              : l10n.voicePackRetry),
                          onPressed: () => model.install(pack),
                        ),
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
      BuildContext context, VoicePacksModel model) async {
    final l10n = AppLocalizations.of(context)!;
    final size = model.installed[pack.id]?.sizeOnDisk ?? pack.downloadSize;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.voicePackDeleteTitle(pack.name)),
        content: Text(l10n.voicePackDeleteBody(formatBytes(context, size))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.voicePackDelete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await model.delete(pack.id);
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: colors.onSecondaryContainer),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: colors.onSecondaryContainer)),
          ),
        ]),
      ),
    );
  }
}

/// The languages [pack] speaks: how many, a few of their names, and, when
/// expanded, all of them.
class VoicePackLanguages extends StatelessWidget {
  final VoicePack pack;
  final String? highlightLanguage;

  const VoicePackLanguages(
      {super.key, required this.pack, this.highlightLanguage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final highlight = highlightLanguage == null
        ? null
        : LanguageTag.bestMatch(highlightLanguage!, pack.languages);
    final languages = sortLanguages(context, pack.languages, first: highlight);
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
              for (var i = 0; i < languages.length; i++)
                Chip(
                  avatar: languages[i] == highlight
                      ? const Icon(Icons.live_tv, size: 16)
                      : null,
                  label: Text(
                    names[i],
                    semanticsLabel: languages[i] == highlight
                        ? '${names[i]}, ${l10n.streamLanguage}'
                        : names[i],
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InstallProgress extends StatelessWidget {
  final VoicePack pack;
  final VoicePackInstallTask task;

  const _InstallProgress({required this.pack, required this.task});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final model = context.read<VoicePacksModel>();
    return StreamBuilder<VoicePackProgress>(
      stream: task.progress,
      initialData: task.latest,
      builder: (context, snapshot) {
        final progress = snapshot.data ?? task.latest;
        final isWaiting = progress.phase == VoicePackInstallPhase.waiting;
        final waitsForWifi = isWaiting && model.waitsForWifi(pack.id);
        final label = switch (progress.phase) {
          VoicePackInstallPhase.waiting =>
            waitsForWifi ? l10n.voicePackWaitingForWifi : l10n.voicePackWaiting,
          VoicePackInstallPhase.downloading => l10n.voicePackDownloading(
              formatBytes(context, progress.downloadedBytes),
              formatBytes(context, progress.totalBytes)),
          VoicePackInstallPhase.verifying => l10n.voicePackVerifying,
          VoicePackInstallPhase.done => l10n.voicePackInstalling,
        };
        final determinate = progress.phase == VoicePackInstallPhase.downloading;
        final percent = (progress.fraction * 100).round();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          child: Column(
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
                    tooltip: l10n.voicePackCancelLabel(pack.name),
                    icon: const Icon(Icons.close),
                    onPressed: () => model.cancel(pack.id),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Semantics(
                  label: l10n.voicePackProgressLabel(pack.name),
                  value: determinate ? '$percent%' : label,
                  child: LinearProgressIndicator(
                      value: determinate ? progress.fraction : null),
                ),
              ),
              if (waitsForWifi)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton.icon(
                      icon: const Icon(Icons.signal_cellular_alt),
                      label: Text(l10n.voicePackUseMobileData),
                      onPressed: () => model.installOverMobileData(pack),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _LicenseDetails extends StatelessWidget {
  final VoicePackLicense license;
  final String packName;

  const _LicenseDetails({required this.license, required this.packName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall;
    final url = license.url;
    final attribution = license.attribution;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.voicePackLicense(licenseName(license)),
              style: theme.textTheme.labelLarge),
          if (attribution != null) ...[
            const SizedBox(height: 4),
            Text(attribution, style: style),
          ],
          if (isOpenRail(license)) ...[
            const SizedBox(height: 4),
            Text(l10n.voicePackOpenRailNotice, style: style),
          ],
          if (url != null)
            TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(l10n.voicePackViewLicense),
              onPressed: () => openUrl(url),
            ),
        ],
      ),
    );
  }
}
