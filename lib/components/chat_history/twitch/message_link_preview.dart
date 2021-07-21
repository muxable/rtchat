import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:flutter/material.dart';

Map<String, _TwitchClipData> linkPreviewCache = {};

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
  if (linkPreviewCache.containsKey(url)) {
    print('$url is already cached');
    return linkPreviewCache[url]!;
  }

  /**
   * if I have app running and send a clip link, url is NOT null,
   * but the data after network fetch 
   * response: {title: Twitch, description: 
   * Twitch is the world's leading video platform and community for gamers., 
   * image: https://static-cdn.jtvnw.net/ttv-static-metadata/twitch_logo3.jpg, 
   * url: null}
   * 
   * but if I were to stop and start the emulator, the fetching
   * works, but any clip links I send would come back null
   * response: {title: Twitch, description: 
   * Twitch is the world's leading video platform and community for gamers., 
   * image: https://static-cdn.jtvnw.net/ttv-static-metadata/twitch_logo3.jpg, 
   * url: null}
   * 
   * also some older clip links wouldn't show either if i were to scroll up.
   * 
   * Weird, I can't figure why.
   */
  print('url to fetch: $url');
  final data = await MetadataFetch.extract(url);
  final response = _TwitchClipData(
      imageUrl: data!.image,
      url: data.url,
      title: data.title,
      description: data.description);
  print("response: $data");
  linkPreviewCache[url] = response;
  return response;
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
  }
}
