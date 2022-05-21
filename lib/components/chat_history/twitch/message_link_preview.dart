import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flutter_image/flutter_image.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';

class TwitchClipData {
  final String? imageUrl;
  final String? url;
  final String? title;
  final String? description;

  const TwitchClipData(
      {required this.imageUrl,
      required this.url,
      required this.title,
      required this.description});
}

Future<TwitchClipData> fetchClipData(String url) async {
  final data = await MetadataFetch.extract(url);
  return TwitchClipData(
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
                          image: ResilientNetworkImage(
                              Uri.parse(snapshot.data.imageUrl))),
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
