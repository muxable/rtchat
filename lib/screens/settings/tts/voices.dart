import 'package:flutter/material.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/voice_packs.dart';
import 'package:rtchat/models/tts/voice_samples.dart';
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
      subtitle: Text(tts.isRandomVoiceEnabled
          ? l10n.perViewerVoiceOnSubtitle
          : l10n.perViewerVoiceOffSubtitle),
      value: tts.isRandomVoiceEnabled,
      onChanged: (value) => tts.isRandomVoiceEnabled = value,
    );
  }
}

/// The languages the installed voice packs speak, the stream's first, each
/// leading to its voices.
class VoiceLanguagesScreen extends StatelessWidget {
  const VoiceLanguagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tts = context.watch<TtsModel>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.voices)),
      body: FutureBuilder<List<String>>(
        // a new future whenever the engines (and so the languages) change.
        future: tts.neuralLanguages(),
        builder: (context, snapshot) {
          final languages = snapshot.data;
          if (languages == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (languages.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.voicesEmpty, textAlign: TextAlign.center),
              ),
            );
          }
          final stream = LanguageTag.bestMatch(
              tts.readingLanguage.languageCode, languages);
          final sorted = sortLanguages(context, languages, first: stream);
          return ListView(
            children: [
              const PerViewerVoiceSwitch(),
              const Divider(),
              for (final language in sorted)
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

  const _LanguageTile(
      {super.key, required this.language, required this.isStreamLanguage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tts = context.watch<TtsModel>();
    final theme = Theme.of(context);
    final name = languageName(context, language);
    return ListTile(
      leading: isStreamLanguage
          ? Tooltip(
              message: l10n.streamLanguage,
              child: Icon(Icons.live_tv, color: theme.colorScheme.primary),
            )
          : const Icon(Icons.language),
      title: Text(name),
      subtitle: FutureBuilder<TtsVoice?>(
        future: tts.voiceFor(language),
        builder: (context, snapshot) {
          final voice = snapshot.data?.name ?? '';
          return Text(isStreamLanguage
              ? [l10n.streamLanguage, if (voice.isNotEmpty) voice].join(' · ')
              : voice);
        },
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => VoicePickerScreen(language: language))),
    );
  }
}

/// The voices for [language]: pick the one that reads it, and play each.
class VoicePickerScreen extends StatelessWidget {
  /// A BCP-47 tag, as the engines list it.
  final String language;

  const VoicePickerScreen({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tts = context.watch<TtsModel>();
    final packs = context.watch<VoicePacksModel>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(languageName(context, language))),
      body: FutureBuilder<(List<TtsVoice>, TtsVoice?)>(
        future: () async {
          final voices = await tts.availableVoices(language);
          return (voices, await tts.voiceFor(language));
        }(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final (voices, selected) = data;
          if (voices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.voicesEmpty, textAlign: TextAlign.center),
              ),
            );
          }
          return ListView(
            children: [
              const PerViewerVoiceSwitch(),
              if (tts.isRandomVoiceEnabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.perViewerVoiceOnSubtitle)),
                    ],
                  ),
                ),
              const Divider(),
              RadioGroup<String>(
                groupValue: selected?.id,
                onChanged: (id) {
                  if (id != null) tts.setVoice(language, id);
                },
                child: Column(
                  children: [
                    for (final voice in voices)
                      _VoiceTile(
                        key: ValueKey(voice.id),
                        language: language,
                        voice: voice,
                        gender: _genderOf(packs, voice),
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

  static String? _genderOf(VoicePacksModel packs, TtsVoice voice) {
    for (final installed in packs.installed.values) {
      for (final speaker in installed.pack.speakers) {
        if (speaker.name == voice.name) return speaker.gender;
      }
    }
    return null;
  }
}

class _VoiceTile extends StatelessWidget {
  final String language;
  final TtsVoice voice;
  final String? gender;

  const _VoiceTile(
      {super.key, required this.language, required this.voice, this.gender});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gender = switch (this.gender) {
      'female' => l10n.voiceFemale,
      'male' => l10n.voiceMale,
      _ => null,
    };
    return RadioListTile<String>(
      value: voice.id,
      title: Text(voice.name),
      subtitle: gender == null ? null : Text(gender),
      secondary: _PreviewButton(language: language, voice: voice),
    );
  }
}

class _PreviewButton extends StatefulWidget {
  final String language;
  final TtsVoice voice;

  const _PreviewButton({required this.language, required this.voice});

  @override
  State<_PreviewButton> createState() => _PreviewButtonState();
}

class _PreviewButtonState extends State<_PreviewButton> {
  var _isPlaying = false;

  Future<void> _play() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final tts = context.read<TtsModel>();
    setState(() => _isPlaying = true);
    try {
      await tts.previewVoice(widget.language, widget.voice.id,
          voiceSample(widget.language, fallback: l10n.sampleMessage));
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.voicePreviewFailed)));
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: l10n.voicePreviewLabel(widget.voice.name),
      onPressed: _isPlaying ? null : _play,
      icon: _isPlaying
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_arrow),
    );
  }
}
