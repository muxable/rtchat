import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/audio_channel.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/screens/settings/dismissible_delete_background.dart';

class AudioSourcesScreen extends StatefulWidget {
  const AudioSourcesScreen({Key? key}) : super(key: key);

  @override
  _AudioSourcesScreenState createState() => _AudioSourcesScreenState();
}

class _AudioSourcesScreenState extends State<AudioSourcesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textEditingController = TextEditingController();
  late final AudioModel _audioModel;

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
      // fetch the title for the page.
      final url = _textEditingController.text;
      final metadata = await MetadataFetch.extract(url);

      final model = Provider.of<AudioModel>(context, listen: false);
      if (!await AudioChannel.hasPermission()) {
        await model.showAudioPermissionDialog(context);
      }
      await model
          .addSource(AudioSource(metadata?.title, Uri.parse(url), false));

      _textEditingController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Audio sources")),
      body: Consumer<AudioModel>(builder: (context, model, child) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile.adaptive(
            title: const Text('Enable off-stream (uses more battery)'),
            subtitle: model.isAlwaysEnabled
                ? const Text('Audio will also play when you\'re offline')
                : const Text('Audio will only play when you\'re online'),
            value: model.isAlwaysEnabled,
            onChanged: (value) {
              model.isAlwaysEnabled = value;
            },
          ),
          const Divider(),
          if (Platform.isIOS)
            const ListTile(
              leading: Icon(Icons.warning),
              title: Text("Hey! Listen!"),
              subtitle: Text(
                  "iOS doesn't support *.ogg media files. Ensure your audio sources use another format, otherwise they won't play."),
              tileColor: Colors.yellow,
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
                  child: CheckboxListTile(
                      title: name == null
                          ? Text(source.url.toString())
                          : Text(name),
                      subtitle:
                          name == null ? null : Text(source.url.toString()),
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
                          hintText: "URL",
                          suffixIcon: IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: () {
                                showModalBottomSheet<void>(
                                    context: context,
                                    builder: (context) {
                                      return MobileScanner(
                                          allowDuplicates: false,
                                          onDetect: (barcode, args) {
                                            final code = barcode.rawValue;
                                            if (code != null) {
                                              _textEditingController.text =
                                                  code;
                                            }
                                            Navigator.of(context).pop();
                                          });
                                    });
                              })),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            Uri.tryParse(value) == null) {
                          return "This doesn't look like a valid URL.";
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
    );
  }
}
