import 'package:flutter/material.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/screens/settings/tts/labels.dart';

/// The switch that gives each viewer their own voice.
class PerViewerVoiceSwitch extends StatelessWidget {
  const PerViewerVoiceSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tts = context.watch<TtsModel>();
    return SwitchListTile.adaptive(
      secondary: const Icon(Icons.groups_outlined),
      title: Text(l10n.perViewerVoice),
      subtitle: Text(l10n.perViewerVoiceSubtitle),
      value: tts.isRandomVoiceEnabled,
      onChanged: (value) => tts.isRandomVoiceEnabled = value,
    );
  }
}

/// The languages the neural voices speak, the stream's first, each leading
/// to its voices.
class VoiceLanguagesScreen extends StatelessWidget {
  const VoiceLanguagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tts = context.watch<TtsModel>();
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.voices)),
      body: FutureBuilder<List<String>>(
        // a new future whenever the model changes, e.g. a pack is installed.
        future: tts.neuralLanguages(),
        builder: (context, snapshot) {
          final languages = snapshot.data ?? const [];
          final stream = LanguageTag.bestMatch(
            tts.readingLanguage.languageCode,
            languages,
          );
          return ListView(
            children: [
              const PerViewerVoiceSwitch(),
              const Divider(),
              for (final language in [
                if (stream != null) stream,
                ...sortLanguages(
                  context,
                  languages.where((language) => language != stream),
                ),
              ])
                _LanguageTile(
                  key: ValueKey(language),
                  language: language,
                  isStreamLanguage: language == stream,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String language;
  final bool isStreamLanguage;

  const _LanguageTile({
    super.key,
    required this.language,
    required this.isStreamLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tts = context.watch<TtsModel>();
    return ListTile(
      leading:
          isStreamLanguage
              ? Icon(
                Icons.live_tv,
                color: Theme.of(context).colorScheme.primary,
                semanticLabel: l10n.streamLanguage,
              )
              : const Icon(Icons.language),
      title: Text(languageName(context, language)),
      subtitle: FutureBuilder<TtsVoice?>(
        future: tts.voiceFor(language),
        builder:
            (context, snapshot) => Text(
              [
                if (isStreamLanguage) l10n.streamLanguage,
                if (snapshot.data case final voice?) voice.name,
              ].join(' · '),
            ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VoicePickerScreen(language: language),
            ),
          ),
    );
  }
}

/// The voices for [language]: pick the one that reads it, and play each.
class VoicePickerScreen extends StatelessWidget {
  /// A BCP-47 tag, as the engine lists it.
  final String language;

  const VoicePickerScreen({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tts = context.watch<TtsModel>();
    return Scaffold(
      appBar: AppBar(title: Text(languageName(context, language))),
      body: FutureBuilder<(List<TtsVoice>, TtsVoice?)>(
        future:
            (() async => (
              await tts.availableVoices(language),
              await tts.voiceFor(language),
            ))(),
        builder: (context, snapshot) {
          final (voices, selected) =
              snapshot.data ?? (const <TtsVoice>[], null);
          return ListView(
            children: [
              // its subtitle says what the picked voice reads.
              const PerViewerVoiceSwitch(),
              const Divider(),
              RadioGroup<String>(
                groupValue: selected?.id,
                onChanged: (id) {
                  if (id != null) tts.setVoice(language, id);
                },
                child: Column(
                  children: [
                    for (final voice in voices)
                      RadioListTile<String>(
                        key: ValueKey(voice.id),
                        value: voice.id,
                        title: Text(voice.name),
                        secondary: IconButton(
                          tooltip: l10n.playSampleMessage,
                          icon: const Icon(Icons.play_arrow),
                          onPressed:
                              () => tts.previewVoice(
                                language,
                                voice.id,
                                l10n.sampleMessage,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
