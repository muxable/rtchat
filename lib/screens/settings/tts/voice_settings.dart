import 'package:flutter/material.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/screens/settings/tts/labels.dart';
import 'package:rtchat/screens/settings/tts/voice_packs.dart';
import 'package:rtchat/screens/settings/tts/voices.dart';

/// The voice that reads chat: the neural voice or the system's, why, and
/// the way to voice packs and voices.
class VoiceSettings extends StatelessWidget {
  const VoiceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tts = context.watch<TtsModel>();
    final fallback = tts.neuralFallback;
    final isNeural = tts.neuralEngine != null && fallback == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(isNeural ? Icons.graphic_eq : Icons.record_voice_over),
          title: Text(isNeural ? l10n.ttsEngineNeural : l10n.ttsEngineSystem),
        ),
        if (fallback != null && tts.isNeuralFallbackNoticePending)
          _Notice(
            text: switch (fallback) {
              NeuralTtsFallback.lowMemoryDevice => l10n.neuralFallbackLowMemory,
              NeuralTtsFallback.loadFailed => l10n.neuralFallbackLoadFailed,
            },
            onDismiss: tts.acknowledgeNeuralFallback,
          )
        else if (isNeural)
          FutureBuilder<List<String>>(
            future: tts.neuralLanguages(),
            builder: (context, snapshot) {
              final language = tts.readingLanguage.languageCode;
              final languages = snapshot.data;
              if (languages == null ||
                  LanguageTag.bestMatch(language, languages) != null) {
                return const SizedBox.shrink();
              }
              return _Notice(
                  text: l10n
                      .languageUnsupported(languageName(context, language)));
            },
          ),
        ListTile(
          leading: const Icon(Icons.download_for_offline_outlined),
          title: Text(l10n.voicePacks),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const VoicePacksScreen())),
        ),
        if (isNeural)
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.voices),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const VoiceLanguagesScreen())),
          ),
        const Divider(),
      ],
    );
  }
}

/// Why chat, or some of it, is read with the system voice.
class _Notice extends StatelessWidget {
  final String text;
  final VoidCallback? onDismiss;

  const _Notice({required this.text, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final onDismiss = this.onDismiss;
    return ListTile(
      leading: Icon(Icons.info_outline,
          color: Theme.of(context).colorScheme.primary),
      title: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      trailing: onDismiss == null
          ? null
          : IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
            ),
    );
  }
}
