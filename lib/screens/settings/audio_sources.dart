import 'package:flutter/material.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:provider/provider.dart';
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

  void add() async {
    if (_formKey.currentState!.validate()) {
      // fetch the title for the page.
      final url = _textEditingController.text;
      final metadata = await MetadataFetch.extract(url);

      await Provider.of<AudioModel>(context, listen: false)
          .addSource(AudioSource(metadata?.title, Uri.parse(url), false));

      _textEditingController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Audio sources")),
      body: Column(children: [
        Consumer<AudioModel>(builder: (context, audioModel, child) {
          return SwitchListTile.adaptive(
            title: const Text('Speaker disconnect prevention'),
            subtitle:
                const Text('Prevent bluetooth speakers from disconnecting'),
            value: audioModel.isSpeakerDisconnectPreventionEnabled,
            onChanged: (value) {
              audioModel.isSpeakerDisconnectPreventionEnabled = value;
            },
          );
        }),
        Consumer<AudioModel>(builder: (context, audioModel, child) {
          return SwitchListTile.adaptive(
            title: const Text('Keep RealtimeChat running in the background'),
            subtitle: audioModel.isForegroundServiceEnabled
                ? const Text(
                    'Audio sources will play even when you\'re using other apps')
                : const Text('Audio sources may not play when you switch apps'),
            value: audioModel.isForegroundServiceEnabled,
            onChanged: (value) {
              audioModel.isForegroundServiceEnabled = value;
            },
          );
        }),
        const Divider(),
        Expanded(
            child: Consumer<AudioModel>(builder: (context, audioModel, child) {
          return ListView(
            children: audioModel.sources.map((source) {
              final name = source.name;
              return Dismissible(
                key: ValueKey(source),
                background: const DismissibleDeleteBackground(),
                child: CheckboxListTile(
                    title:
                        name == null ? Text(source.url.toString()) : Text(name),
                    subtitle: name == null ? null : Text(source.url.toString()),
                    value: !source.muted,
                    onChanged: (value) {
                      audioModel.toggleSource(source);
                    }),
                onDismissed: (direction) {
                  audioModel.removeSource(source);
                },
              );
            }).toList(),
          );
        })),
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Form(
            key: _formKey,
            child: Row(children: [
              Expanded(
                child: TextFormField(
                    controller: _textEditingController,
                    decoration: const InputDecoration(hintText: "URL"),
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
      ]),
    );
  }
}
