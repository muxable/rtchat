import 'package:flutter/material.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/voice_packs.dart';
import 'package:rtchat/screens/settings/tts/fallback_notice.dart';
import 'package:rtchat/screens/settings/tts/labels.dart';
import 'package:rtchat/screens/settings/tts/voice_packs.dart';
import 'package:rtchat/screens/settings/tts/voices.dart';

class TextToSpeechScreen extends StatefulWidget {
  const TextToSpeechScreen({super.key});

  @override
  State<TextToSpeechScreen> createState() => _TextToSpeechScreenState();
}

class _TextToSpeechScreenState extends State<TextToSpeechScreen> {
  @override
  void initState() {
    super.initState();
    context.read<VoicePacksModel>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final voicePacks = context.watch<VoicePacksModel>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.textToSpeech)),
      body: Consumer<TtsModel>(builder: (context, model, child) {
        return ListView(
          children: [
            if (voicePacks.isSupported) ...[
              const NeuralFallbackBanner(),
              const VoicePackSuggestion(),
            ],
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  model.say(
                      l10n,
                      SystemMessageModel(
                        text: l10n.sampleMessage,
                      ),
                      force: true);
                },
                child: Text(l10n.playSampleMessage),
              ),
            ),
            const SizedBox(height: 8),
            if (voicePacks.isSupported) const VoiceSettings(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.textToSpeechRate,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      )),
                  Slider.adaptive(
                    value: model.speed,
                    min: 0.0,
                    max: 1.0,
                    label: "speed: ${model.speed}",
                    onChanged: (value) {
                      model.speed = value;
                    },
                  ),
                  Text(l10n.textToSpeechPitch,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      )),
                  Slider.adaptive(
                    value: model.pitch,
                    min: 0.1,
                    max: 2,
                    label: "${model.pitch}",
                    onChanged: (value) {
                      model.pitch = value;
                    },
                  ),
                ],
              ),
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.muteBots),
              value: model.isBotMuted,
              onChanged: (value) {
                model.isBotMuted = value;
              },
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.muteEmotes),
              value: model.isEmoteMuted,
              onChanged: (value) {
                model.isEmoteMuted = value;
              },
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.muteViewerNames),
              value: model.isPreludeMuted,
              onChanged: (value) {
                model.isPreludeMuted = value;
              },
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.subscribersOnly),
              value: model.isSubscribersOnly,
              onChanged: (value) {
                model.isSubscribersOnly = value;
              },
            ),
          ],
        );
      }),
    );
  }
}

/// The voice that reads chat: which engine, whether it speaks the stream's
/// language, and the way to voice packs and voices.
class VoiceSettings extends StatelessWidget {
  const VoiceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tts = context.watch<TtsModel>();
    final packs = context.watch<VoicePacksModel>();
    final theme = Theme.of(context);
    final installedCount = packs.installed.length;
    final streamLanguage = tts.readingLanguage.languageCode;
    // a voice pack is installed and neural voices can run on this device.
    final isNeural = packs.hasInstalledPack && tts.neuralFallback == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(l10n.ttsVoiceSection,
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              )),
        ),
        ListTile(
          leading: Icon(isNeural ? Icons.graphic_eq : Icons.record_voice_over),
          title: Text(l10n.ttsEngine),
          subtitle:
              Text(isNeural ? l10n.ttsEngineNeural : l10n.ttsEngineSystem),
        ),
        if (isNeural && !packs.isInstalledFor(streamLanguage))
          UnsupportedLanguageRow(language: streamLanguage),
        ListTile(
          leading: const Icon(Icons.download_for_offline_outlined),
          title: Text(l10n.voicePacks),
          subtitle: Text(installedCount == 0
              ? l10n.voicePacksSubtitleNone
              : l10n.voicePacksSubtitleInstalled(
                  installedCount, formatBytes(context, packs.storageUsed))),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const VoicePacksScreen())),
        ),
        if (packs.hasInstalledPack) ...[
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.voices),
            subtitle: Text(l10n.voicesSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const VoiceLanguagesScreen())),
          ),
          const PerViewerVoiceSwitch(),
        ],
        const Divider(),
      ],
    );
  }
}

/// Says that the installed voice packs don't speak [language], so the
/// system voice reads it.
class UnsupportedLanguageRow extends StatelessWidget {
  final String language;

  const UnsupportedLanguageRow({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.info_outline, color: colors.primary),
      subtitle: Text(l10n.languageUnsupported(languageName(context, language)),
          style: TextStyle(color: colors.onSurface)),
    );
  }
}

/// Suggests downloading the voice pack for the stream's language (or the
/// device's) while text to speech is on and no voice pack is installed,
/// until it's dismissed.
class VoicePackSuggestion extends StatelessWidget {
  const VoicePackSuggestion({super.key});

  /// The pack to suggest, and the language it's suggested for.
  static (VoicePack, String)? suggestion(
      VoicePacksModel packs, Iterable<String> languages) {
    for (final language in languages) {
      final pack = packs.packFor(language);
      if (pack != null) return (pack, language);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tts = context.watch<TtsModel>();
    final packs = context.watch<VoicePacksModel>();
    if (tts.mode == TtsMode.disabled ||
        tts.isVoicePackSuggestionDismissed ||
        !packs.isLoaded ||
        packs.hasInstalledPack ||
        packs.isInstalling) {
      return const SizedBox.shrink();
    }
    final found = suggestion(packs, [
      tts.readingLanguage.languageCode,
      WidgetsBinding.instance.platformDispatcher.locale.languageCode,
    ]);
    if (found == null) return const SizedBox.shrink();
    final (pack, language) = found;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.auto_awesome,
                  color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.voicePackSuggestionTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              l10n.voicePackSuggestionBody(
                  pack.name,
                  formatBytes(context, pack.downloadSize),
                  languageName(context, language)),
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => tts.isVoicePackSuggestionDismissed = true,
                  child: Text(l10n.notNow),
                ),
                Semantics(
                  container: true,
                  button: true,
                  label: l10n.voicePackDownloadLabel(pack.name),
                  excludeSemantics: true,
                  child: TextButton.icon(
                    icon: const Icon(Icons.download),
                    label: Text(l10n.voicePackDownload),
                    onPressed: () {
                      packs.install(pack);
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const VoicePacksScreen()));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
