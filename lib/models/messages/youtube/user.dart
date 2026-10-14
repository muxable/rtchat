import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/chat.dart';

/// A YouTube chat author, from a `LiveChatMessage`'s `authorDetails`.
class YouTubeUserModel implements ChatUser {
  /// The author's YouTube channel ID, e.g. `UC...`.
  @override
  final String userId;
  @override
  final String? displayName;
  final String? channelUrl;
  final String? profileImageUrl;
  final bool isVerified;
  final bool isChatOwner;

  /// Whether the author is a channel member.
  final bool isChatSponsor;
  final bool isChatModerator;

  const YouTubeUserModel(
      {required this.userId,
      this.displayName,
      this.channelUrl,
      this.profileImageUrl,
      this.isVerified = false,
      this.isChatOwner = false,
      this.isChatSponsor = false,
      this.isChatModerator = false});

  /// Parses `authorDetails` (or `bannedUserDetails`).
  factory YouTubeUserModel.fromJson(Map<String, dynamic> json) {
    final displayName = json['displayName'] as String?;
    final picture = json['profileImageUrl'] as String?;
    return YouTubeUserModel(
      userId: json['channelId']?.toString() ?? '',
      displayName:
          displayName == null || displayName.isEmpty ? null : displayName,
      channelUrl: json['channelUrl'] as String?,
      profileImageUrl: picture == null || picture.isEmpty ? null : picture,
      isVerified: json['isVerified'] == true,
      isChatOwner: json['isChatOwner'] == true,
      isChatSponsor: json['isChatSponsor'] == true,
      isChatModerator: json['isChatModerator'] == true,
    );
  }

  @override
  String get provider => Providers.youtube;

  /// YouTube has no separate login, so this is the display name (usually an
  /// `@handle`) lowercased, falling back to the channel ID.
  @override
  String get login => displayName?.toLowerCase() ?? userId;

  @override
  bool get isBot => _bots.contains(login.replaceFirst('@', ''));

  @override
  bool operator ==(other) =>
      other is YouTubeUserModel && other.userId == userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => login;
}

const _bots = {"nightbot", "streamelements", "streamlabs", "moobot"};
