import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/audio_channel.dart';
import 'package:rtchat/components/scanner_error.dart';
import 'package:rtchat/components/scanner_settings.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/screens/settings/dismissible_delete_background.dart';

// Helper functions for URL validation
bool hasFileExtension(Uri uri) {
  final segments = uri.pathSegments;
  if (segments.isNotEmpty) {
    final last = segments.last;
    return last.contains('.') && last.split('.').last.length > 1;
  }
  return false;
}

bool isOgg(Uri uri) {
  return uri.path.toLowerCase().endsWith('.ogg');
}

bool isHttpOnIOS(Uri uri) {
  return (Platform.isIOS || Platform.isMacOS) && uri.scheme == 'http';
}

class AudioSourcesScreen extends StatefulWidget {
  const AudioSourcesScreen({super.key});

  @override
  State<AudioSourcesScreen> createState() => _AudioSourcesScreenState();
}

class _AudioSourcesScreenState extends State<AudioSourcesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textEditingController = TextEditingController();
  late final AudioModel _audioModel;
  MobileScannerController _scanController = MobileScannerController(
    // facing: CameraFacing.back,
    // torchEnabled: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void initState() {
    super.initState();
    _audioModel = Provider.of<AudioModel>(context, listen: false);
    // tell the audio model we're on the settings page.
    _audioModel.isSettingsVisible = true;
  }

  @override
  void dispose() {
    // tell the audio model we're off the settings page.
    _audioModel.isSettingsVisible = false;
    super.dispose();
  }

  void add() async {
    if (_formKey.currentState!.validate()) {
      final urlStr = _textEditingController.text;
      final uri = Uri.tryParse(urlStr);

      // New validation logic:
      if (uri == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid URL."))
        );
        return;
      }

      // Warn for missing file extension on iOS/macOS
      if ((Platform.isIOS || Platform.isMacOS) && !hasFileExtension(uri)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Audio file URLs must have a file extension (e.g. .mp3, .wav) on iOS/macOS. See https://github.com/bluefireteam/audioplayers/blob/main/troubleshooting.md#ios-macos-urls-or-paths-without-a-file-extension")
          )
        );
        return;
      }

      // Warn for .ogg on iOS
      if (Platform.isIOS && isOgg(uri)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("iOS does not support .ogg format. Please use .mp3 or .wav. See https://github.com/bluefireteam/audioplayers/blob/main/troubleshooting.md#supported-formats--encodings")
          )
        );
        return;
      }

      // Warn for HTTP on iOS/macOS
      if (isHttpOnIOS(uri)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Non-HTTPS URLs may not work on iOS/macOS. See https://github.com/bluefireteam/audioplayers/blob/main/troubleshooting.md#unsafe-http")
          )
        );
        // Allow user to continue, don't return
      }

      Metadata? metadata;
      try {
        metadata = await MetadataFetch.extract(urlStr);
      } catch (e) {
        metadata = null;
      }
      final title = metadata?.title ?? uri.host;

      if (!mounted) return;
      final model = Provider.of<AudioModel>(context, listen: false);
      if (!await AudioChannel.hasPermission()) {
        if (!mounted) return;
        await model.showAudioPermissionDialog(context);
      }
      await model.addSource(AudioSource(title, uri, false));
      if (!mounted) return;
      _textEditingController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.audioSources)),
      body: SafeArea(
        child: Consumer<AudioModel>(builder: (context, model, child) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile.adaptive(
                  title: Text(
                      AppLocalizations.of(context)!.enableOffStreamSwitchTitle),
                  subtitle: model.isAlwaysEnabled
                      ? Text(AppLocalizations.of(context)!
                          .enableOffStreamSwitchEnabledSubtitle)
                      : Text(AppLocalizations.of(context)!
                          .enableOffStreamSwitchDisabledSubtitle),
                  value: model.isAlwaysEnabled,
                  onChanged: (value) {
                    model.isAlwaysEnabled = value;
                  },
                ),
                const Divider(),
                if (Platform.isIOS)
                  ListTile(
                    leading: const Icon(Icons.warning),
                    title:
                        Text(AppLocalizations.of(context)!.iosOggWarningTitle),
                    subtitle: Text(
                        AppLocalizations.of(context)!.iosOggWarningSubtitle),
                    tileColor: Colors.yellow,
                    textColor: Colors.black,
                  )
                else
                  Container(),
                Expanded(
                  child: ListView(
                    children: model.sources.map((source) {
                      final name = source.name;
                      return Dismissible(
                        key: ValueKey(source),
                        background: const DismissibleDeleteBackground(),
                        child: CheckboxListTile.adaptive(
                            title: name == null
                                ? Text(source.url.toString())
                                : Text(name),
                            subtitle: name == null
                                ? null
                                : Text(source.url.toString()),
                            value: !source.muted,
                            onChanged: (value) {
                              model.toggleSource(source);
                            }),
                        onDismissed: (direction) {
                          model.removeSource(source);
                        },
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 16),
                  child: Form(
                    key: _formKey,
                    child: Row(children: [
                      Expanded(
                        child: TextFormField(
                            controller: _textEditingController,
                            decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.url,
                                suffixIcon: IconButton(
                                    icon: const Icon(Icons.qr_code_scanner),
                                    onPressed: () {
                                      final messenger =
                                          ScaffoldMessenger.of(context);

                                      showModalBottomSheet(
                                        isScrollControlled: true,
                                        context: context,
                                        builder: (ctx) {
                                          return Stack(
                                            children: [
                                              MobileScanner(
                                                errorBuilder:
                                                    (context, error, child) {
                                                  return ScannerErrorWidget(
                                                      error: error);
                                                },
                                                controller: _scanController,
                                                onDetect: (capture) {
                                                  final List<Barcode> barcodes =
                                                      capture.barcodes;

                                                  if (barcodes.isEmpty) {
                                                    messenger.showSnackBar(SnackBar(
                                                        content: Text(
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .invalidUrlErrorText)));
                                                  }

                                                  final barcode =
                                                      barcodes.first;

                                                  if (barcode.rawValue ==
                                                          null ||
                                                      barcode
                                                          .rawValue!.isEmpty) {
                                                    messenger.showSnackBar(SnackBar(
                                                        content: Text(
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .invalidUrlErrorText)));

                                                    Navigator.pop(ctx);
                                                  }

                                                  _textEditingController.text =
                                                      '${barcode.rawValue}';

                                                  Navigator.pop(ctx);
                                                },
                                              ),
                                              Positioned(
                                                  top: 50,
                                                  left: 0,
                                                  right: 0,
                                                  child: ScannerSettings(
                                                      scanController:
                                                          _scanController)),
                                            ],
                                          );
                                        },
                                      ).then((value) {
                                        _scanController.dispose();

                                        //re initialize controller
                                        _scanController =
                                            MobileScannerController(
                                          detectionSpeed:
                                              DetectionSpeed.noDuplicates,
                                        );
                                      });
                                    })),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  Uri.tryParse(value) == null) {
                                return AppLocalizations.of(context)!
                                    .invalidUrlErrorText;
                              }
                              return null;
                            },
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                            onEditingComplete: add),
                      ),
                      IconButton(icon: const Icon(Icons.add), onPressed: add),
                    ]),
                  ),
                ),
              ]);
        }),
      ),
    );
  }
}
