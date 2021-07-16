import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:rtchat/models/style.dart';

class _TwitchClipData {
  final String? imageUrl;
  final String? url;
  final String? title;
  final String? description;

  const _TwitchClipData(
      {required this.imageUrl,
      required this.url,
      required this.title,
      required this.description});
}

Future<_TwitchClipData> fetchClipData(String url) async {
  final data = await MetadataFetch.extract(url);
  return _TwitchClipData(
      imageUrl: data!.image,
      url: data.url,
      title: data.title,
      description: data.description);
}

class TwitchMessageLinkPreviewWidget extends StatelessWidget {
  final TextStyle messageStyle;
  final List<InlineSpan> children;
  final String url;

  const TwitchMessageLinkPreviewWidget(
      this.messageStyle, this.children, this.url,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<StyleModel>(builder: (context, styleModel, child) {
      return (Column(
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: RichText(
                text: TextSpan(style: messageStyle, children: children),
              )),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: FutureBuilder(
                  future: fetchClipData(url),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Card(child: CircularProgressIndicator());
                    }
                    return Card(
                      child: ListTile(
                        leading: Image.network(snapshot.data.imageUrl),
                        title: Text(snapshot.data.title),
                        subtitle: Text(snapshot.data.description),
                        isThreeLine: true,
                      ),
                    );
                  }))
        ],
      ));
    });
  }
}
