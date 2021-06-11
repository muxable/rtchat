import 'package:flutter/material.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/audio.dart';
import 'package:rtchat/screens/settings/dismissible_delete_background.dart';

class AudioSourcesScreen extends StatefulWidget {
  @override
  _AudioSourcesScreenState createState() => _AudioSourcesScreenState();
}

class _AudioSourcesScreenState extends State<AudioSourcesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Provider.of<AudioModel>(context, listen: false)
        .setTemporaryMutedState(false);
  }

  @override
  void dispose() {
    // TODO: this model reference might not be correct anymore. we should instead find a way to guarantee we're bound to the same audio model.
    Provider.of<AudioModel>(context, listen: false)
        .setTemporaryMutedState(true);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Audio sources")),
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
            title: const Text('Auto mute'),
            subtitle: const Text('Mute sounds if your stream isn\'t online'),
            value: audioModel.isAutoMuteEnabled,
            onChanged: (value) {
              audioModel.isAutoMuteEnabled = value;
            },
          );
        }),
        Divider(),
        Expanded(
            child: Consumer<AudioModel>(builder: (context, audioModel, child) {
          return ListView(
            children: audioModel.sources.map((source) {
              final name = source.name;
              return Dismissible(
                key: ValueKey(source),
                background: DismissibleDeleteBackground(),
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
        Divider(),
        Padding(
          padding: EdgeInsets.only(left: 16, bottom: 16),
          child: Form(
            key: _formKey,
            child: Row(children: [
              Expanded(
                child: TextFormField(
                    controller: _textEditingController,
                    decoration: InputDecoration(hintText: "URL"),
                    validator: (value) {
                      if (value == null || Uri.tryParse(value) == null) {
                        return "This doesn't look like a valid URL.";
                      }
                      return null;
                    }),
              ),
              IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // fetch the title for the page.
                      final url = _textEditingController.text;
                      final metadata = await MetadataFetch.extract(url);

                      Provider.of<AudioModel>(context, listen: false).addSource(
                          AudioSource(metadata?.title, Uri.parse(url), false));
                    }
                  }),
            ]),
          ),
        ),
      ]),
    );
  }
}
