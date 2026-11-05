import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rtchat/in_app_update_service.dart';

class AppUpdateHandler extends StatefulWidget {
  final Widget child;

  const AppUpdateHandler({
    super.key,
    required this.child,
  });

  @override
  State<AppUpdateHandler> createState() => _AppUpdateHandlerState();
}

class _AppUpdateHandlerState extends State<AppUpdateHandler>
    with WidgetsBindingObserver {
  final InAppUpdateService _updateService = InAppUpdateService.instance;

  StreamSubscription<Map<String, dynamic>>? _subscription;

  bool _promptVisible = false;
  bool _restartDialogVisible = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initialize();
  }

  Future<void> _initialize() async {
    await _updateService.initialize();

    _subscription = _updateService.events.listen(_handleUpdateEvent);

    await _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    if (!mounted || _promptVisible) return;

    final update = await _updateService.checkForUpdate();

    if (!mounted || update == null) return;

    await _showUpdatePrompt(
      update['stalenessDays'] as int? ?? 21,
    );
  }

  Future<void> _handleUpdateEvent(
    Map<String, dynamic> event,
  ) async {
    if (!mounted) return;

    switch (event['event']) {
      case 'updateDownloaded':
        await _showRestartDialog();
        break;

      case 'downloadProgress':
        // You can use these values to update a progress indicator.
        final downloaded = event['bytesDownloaded'] as int? ?? 0;
        final total = event['totalBytesToDownload'] as int? ?? 0;

        debugPrint('Update progress: $downloaded / $total');
        break;

      case 'updateFailed':
        debugPrint('Update failed: ${event['error']}');
        break;
    }
  }

  Future<void> _showUpdatePrompt(int stalenessDays) async {
    if (!mounted || _promptVisible) return;

    _promptVisible = true;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update available'),
          content: const Text(
            'A newer version of the app is available. '
            'Would you like to download it now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    _promptVisible = false;

    if (!mounted) return;

    if (accepted == true) {
      final started = await _updateService.startFlexibleUpdate();

      if (!started && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Unable to start the update. Please try again later.'),
          ),
        );
      }
    } else {
      await _updateService.recordDismissal();
    }
  }

  Future<void> _showRestartDialog() async {
    if (!mounted || _restartDialogVisible) return;

    _restartDialogVisible = true;

    final restart = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update downloaded'),
          content: const Text(
            'The update is ready to install. '
            'Restart the app to finish updating.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restart now'),
            ),
          ],
        );
      },
    );

    _restartDialogVisible = false;

    if (!mounted) return;

    if (restart == true) {
      await _updateService.completeUpdate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateService.checkDownloadedUpdate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
