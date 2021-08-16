import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image/flutter_image.dart';

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
      {required this.messageStyle,
      required this.children,
      required this.url,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text.rich(
              TextSpan(style: messageStyle, children: children),
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
                      leading: Image(
                          image: NetworkImageWithRetry(snapshot.data.imageUrl)),
                      title: Text(snapshot.data.title),
                      subtitle: Text(snapshot.data.description),
                      isThreeLine: true,
                    ),
                  );
                }))
      ],
    );
  }
}
