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

class BadgeVersion {
  final String id;
  final String imageUrl1x;
  final String imageUrl2x;
  final String imageUrl4x;
  final String description;
  final String title;
  final String? clickAction;
  final String? clickUrl;

  BadgeVersion({
    required this.id,
    required this.imageUrl1x,
    required this.imageUrl2x,
    required this.imageUrl4x,
    required this.description,
    required this.title,
    required this.clickAction,
    required this.clickUrl,
  });
}

class TwitchBadgeInfo {
  final String setId;
  final List<BadgeVersion> versions;

  TwitchBadgeInfo({
    required this.setId,
    required this.versions,
  });
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

  Future<List<TwitchBadgeInfo>> getTwitchBadges({String? channelId}) async {
    const int maxAttempts = 10;
    const int baseDelay = 1; // in seconds

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final result = await functions
            .httpsCallable("getBadges")
            .call({"provider": "twitch", "channelId": channelId});
        if (result.data == null) {
          return [];
        }
        return result.data
            .map<TwitchBadgeInfo>((badgeInfo) => TwitchBadgeInfo(
                  setId: badgeInfo["set_id"],
                  versions: badgeInfo["versions"]
                      .map<BadgeVersion>((version) => BadgeVersion(
                            id: version["id"],
                            imageUrl1x: version["image_url_1x"],
                            imageUrl2x: version["image_url_2x"],
                            imageUrl4x: version["image_url_4x"],
                            description: version["description"],
                            title: version["title"],
                            clickAction: version["click_action"],
                            clickUrl: version["click_url"],
                          ))
                      .toList(),
                ))
            .toList();
      } catch (e) {
        if (e is FirebaseFunctionsException && e.code == 'unavailable') {
          if (attempt < maxAttempts - 1) {
            await Future.delayed(Duration(seconds: baseDelay * (1 << attempt)));
          } else {
            // Handle the "UNAVAILABLE" error gracefully beyond the 10 attempts
            return [];
          }
        } else {
          rethrow;
        }
      }
    }
    return [];
  }
}
