import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';

/// Tells the user, once, that chat is read with the system voice because
/// neural voices can't run ([TtsModel.neuralFallback]): a banner in the text
/// to speech settings ([NeuralFallbackBanner]) and a snack bar on the chat
/// screen while text to speech is on ([NeuralFallbackSnackBarListener]).
/// Whichever is dismissed first acknowledges it
/// ([TtsModel.acknowledgeNeuralFallback]), and neither shows again.
class NeuralFallbackBanner extends StatelessWidget {
  const NeuralFallbackBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final tts = context.watch<TtsModel>();
    final fallback = tts.neuralFallback;
    if (!tts.isNeuralFallbackNoticePending || fallback == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (title, body) = switch (fallback) {
      NeuralTtsFallback.lowMemoryDevice => (
          l10n.neuralFallbackLowMemoryTitle,
          l10n.neuralFallbackLowMemoryBody
        ),
      NeuralTtsFallback.loadFailed => (
          l10n.neuralFallbackLoadFailedTitle,
          l10n.neuralFallbackLoadFailedBody
        ),
    };
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.record_voice_over, color: colors.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: colors.onTertiaryContainer)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(body, style: TextStyle(color: colors.onTertiaryContainer)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: tts.acknowledgeNeuralFallback,
                child: Text(l10n.gotIt),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a snack bar, once, when chat starts being read with the system
/// voice because neural voices can't run, while text to speech is on and a
/// voice pack is installed. It counts as acknowledged once it closes.
class NeuralFallbackSnackBarListener extends StatefulWidget {
  final Widget child;

  const NeuralFallbackSnackBarListener({super.key, required this.child});

  @override
  State<NeuralFallbackSnackBarListener> createState() =>
      _NeuralFallbackSnackBarListenerState();
}

class _NeuralFallbackSnackBarListenerState
    extends State<NeuralFallbackSnackBarListener> {
  TtsModel? _tts;
  var _isShowing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tts = context.read<TtsModel>();
    if (!identical(tts, _tts)) {
      _tts?.removeListener(_check);
      _tts = tts..addListener(_check);
      _check();
    }
  }

  void _check() {
    final tts = _tts;
    if (tts == null ||
        _isShowing ||
        !tts.isNeuralFallbackNoticePending ||
        tts.neuralFallback == null ||
        tts.mode == TtsMode.disabled ||
        tts.neuralEngines.isEmpty) {
      return;
    }
    _isShowing = true;
    // listeners can be called during a build.
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => _show(tts))
      ..ensureVisualUpdate();
  }

  void _show(TtsModel tts) {
    final fallback = tts.neuralFallback;
    if (!mounted || fallback == null || !tts.isNeuralFallbackNoticePending) {
      _isShowing = false;
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final controller = ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(switch (fallback) {
        NeuralTtsFallback.lowMemoryDevice =>
          l10n.neuralFallbackLowMemorySnackBar,
        NeuralTtsFallback.loadFailed => l10n.neuralFallbackLoadFailedSnackBar,
      }),
      duration: const Duration(seconds: 10),
      // it goes away by itself, though it has an action.
      persist: false,
      action: SnackBarAction(label: l10n.gotIt, onPressed: () {}),
    ));
    controller.closed.then((_) {
      _isShowing = false;
      tts.acknowledgeNeuralFallback();
    });
  }

  @override
  void dispose() {
    _tts?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
