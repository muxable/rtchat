import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:flutter/material.dart';
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

class TwitchMessageLinkPreviewWidget extends StatefulWidget {
  final String url;

  const TwitchMessageLinkPreviewWidget({required this.url, Key? key})
      : super(key: key);

  @override
  State<TwitchMessageLinkPreviewWidget> createState() =>
      _TwitchMessageLinkPreviewWidgetState();
}

class _TwitchMessageLinkPreviewWidgetState
    extends State<TwitchMessageLinkPreviewWidget> {
  TwitchClipData? _data;

  @override
  void initState() {
    super.initState();

    // this approach instead of FutureBuilder prevents a flash of a loading
    // indicator on subsequent rerender.
    fetchClipData(widget.url).then((data) {
      if (!mounted) {
        return;
      }
      setState(() {
        _data = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Card(child: CircularProgressIndicator()));
    }
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Card(
          child: ListTile(
            leading: data.imageUrl == null
                ? null
                : Image(
                    image: ResilientNetworkImage(Uri.parse(data.imageUrl!))),
            title: data.title == null ? null : Text(data.title!),
            subtitle: data.description == null ? null : Text(data.description!),
            isThreeLine: true,
          ),
        ));
  }
}
