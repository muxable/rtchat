import 'dart:io';

import 'package:flutter/material.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:path_provider/path_provider.dart';

/// Lists, installs and deletes voice packs. Only reachable in debug builds
/// until the neural engine can speak with them, so it isn't translated.
class VoicePacksDebugScreen extends StatefulWidget {
  const VoicePacksDebugScreen({super.key});

  @override
  State<VoicePacksDebugScreen> createState() => _VoicePacksDebugScreenState();
}

class _VoicePacksDebugScreenState extends State<VoicePacksDebugScreen> {
  VoicePackRepository? _repository;
  List<VoicePack> _packs = const [];
  Map<String, InstalledVoicePack> _installed = const {};
  final _statuses = <String, VoicePackStatus>{};
  bool _allowMobileData = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final support = await getApplicationSupportDirectory();
      // No connectivity check is wired up yet, so Wi-Fi-only downloads need
      // the switch below.
      final repository = VoicePackRepository(
          directory: Directory('${support.path}/voice_packs'));
      await repository.cleanUp();
      if (!mounted) {
        await repository.dispose();
        return;
      }
      _repository = repository;
      await _refresh();
    } catch (e) {
      setState(() => _error = e);
    }
  }

  Future<void> _refresh() async {
    final repository = _repository!;
    final packs = await repository.availablePacks();
    final installed = await repository.installedPacks();
    final statuses = {
      for (final pack in packs) pack.id: await repository.status(pack),
    };
    if (!mounted) return;
    setState(() {
      _packs = packs;
      _installed = installed;
      _statuses
        ..clear()
        ..addAll(statuses);
    });
  }

  Future<void> _install(VoicePack pack) async {
    final task = _repository!.install(pack, allowMetered: _allowMobileData);
    setState(() => _statuses[pack.id] = VoicePackStatus.installing);
    try {
      await task.done;
    } on VoicePackException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${pack.name}: $e')));
      }
    }
    if (mounted) await _refresh();
  }

  Future<void> _delete(VoicePack pack) async {
    await _repository!.delete(pack.id);
    if (mounted) await _refresh();
  }

  @override
  void dispose() {
    _repository?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = _repository;
    return Scaffold(
      appBar: AppBar(title: const Text('Voice packs (debug)')),
      body: _error != null
          ? Center(child: Text('$_error'))
          : repository == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(children: [
                  SwitchListTile.adaptive(
                    title: const Text('Allow mobile data'),
                    subtitle: const Text('Downloads are Wi-Fi only by default'),
                    value: _allowMobileData,
                    onChanged: (value) =>
                        setState(() => _allowMobileData = value),
                  ),
                  for (final pack in _packs)
                    _PackTile(
                      pack: pack,
                      status:
                          _statuses[pack.id] ?? VoicePackStatus.notInstalled,
                      installed: _installed[pack.id],
                      task: repository.task(pack.id),
                      onInstall: () => _install(pack),
                      onDelete: () => _delete(pack),
                    ),
                ]),
    );
  }
}

String _megabytes(int bytes) => '${(bytes / 1e6).toStringAsFixed(1)} MB';

class _PackTile extends StatelessWidget {
  final VoicePack pack;
  final VoicePackStatus status;
  final InstalledVoicePack? installed;
  final VoicePackInstallTask? task;
  final VoidCallback onInstall;
  final VoidCallback onDelete;

  const _PackTile({
    required this.pack,
    required this.status,
    required this.installed,
    required this.task,
    required this.onInstall,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final installed = this.installed;
    final details = [
      pack.languages.join(', '),
      '${pack.speakers.length} speakers',
      'download ${_megabytes(pack.downloadSize)}',
      if (installed != null) 'on disk ${_megabytes(installed.sizeOnDisk)}',
      if (status == VoicePackStatus.upgradeAvailable) 'upgrade available',
      if (pack.license != null) pack.license!.name,
    ].join(' · ');
    final task = this.task;
    return ListTile(
      title: Text(pack.name),
      subtitle: task == null
          ? Text(details)
          : StreamBuilder<VoicePackProgress>(
              stream: task.progress,
              initialData: task.latest,
              builder: (context, snapshot) {
                final progress = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${progress.phase.name} '
                        '${_megabytes(progress.downloadedBytes)} of '
                        '${_megabytes(progress.totalBytes)}'),
                    LinearProgressIndicator(value: progress.fraction),
                  ],
                );
              },
            ),
      trailing: switch (status) {
        VoicePackStatus.installing => IconButton(
            tooltip: 'Cancel',
            icon: const Icon(Icons.close),
            onPressed: task?.cancel,
          ),
        VoicePackStatus.notInstalled => IconButton(
            tooltip: 'Download',
            icon: const Icon(Icons.download),
            onPressed: onInstall,
          ),
        VoicePackStatus.installed || VoicePackStatus.upgradeAvailable => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == VoicePackStatus.upgradeAvailable)
                IconButton(
                  tooltip: 'Upgrade',
                  icon: const Icon(Icons.upgrade),
                  onPressed: onInstall,
                ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete),
                onPressed: onDelete,
              ),
            ],
          ),
      },
    );
  }
}
