import 'package:cloud_functions/cloud_functions.dart';

class Viewers {
  final List<String> broadcaster;
  final List<String> moderators;
  final List<String> vips;
  final List<String> viewers;

  Viewers({
    required this.broadcaster,
    required this.moderators,
    required this.vips,
    required this.viewers,
  });

  // create a new instance that filters to viewers matching a certain substring.
  Viewers query(String text) {
    if (text.isEmpty) {
      return this;
    }
    return Viewers(
      broadcaster: broadcaster
          .where((name) => name.toLowerCase().contains(text.toLowerCase()))
          .take(10)
          .toList(),
      moderators: moderators
          .where((name) => name.toLowerCase().contains(text.toLowerCase()))
          .take(10)
          .toList(),
      vips: vips
          .where((name) => name.toLowerCase().contains(text.toLowerCase()))
          .take(10)
          .toList(),
      viewers: viewers
          .where((name) => name.toLowerCase().contains(text.toLowerCase()))
          .take(10)
          .toList(),
    );
  }

  // flatten the viewers to a list
  List<String> flatten() {
    return broadcaster + moderators + vips + viewers;
  }
}

class ChatStateAdapter {
  final FirebaseFunctions functions;

  ChatStateAdapter._({required this.functions});

  static ChatStateAdapter get instance =>
      _instance ??= ChatStateAdapter._(functions: FirebaseFunctions.instance);
  static ChatStateAdapter? _instance;

  Future<Viewers> getViewers({required String channelId}) {
    return functions
        .httpsCallable("getViewerList")
        .call(channelId)
        .then((result) {
      return Viewers(
        broadcaster: [...(result.data['broadcaster'] ?? [])],
        moderators: [...(result.data['moderators'] ?? [])],
        vips: [...(result.data['vips'] ?? [])],
        viewers: [...(result.data['viewers'] ?? [])],
      );
    });
  }
}
