import 'package:flutter/material.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/chat.dart';

/// A badge from a Kick sender's identity, e.g. moderator or subscriber.
class KickBadge {
  final String type;
  final String text;
  final int? count;

  const KickBadge({required this.type, required this.text, this.count});

  factory KickBadge.fromJson(Map<String, dynamic> json) => KickBadge(
    type: json['type'] ?? '',
    text: json['text'] ?? '',
    count: json['count'],
  );
}

class KickUserModel implements ChatUser {
  @override
  final String userId;
  @override
  final String login;
  @override
  final String? displayName;

  /// The user's chosen name color, e.g. `#FF5733`.
  final String? usernameColor;
  final List<KickBadge> badges;
  final String? profilePictureUrl;

  const KickUserModel({
    required this.userId,
    required this.login,
    this.displayName,
    this.usernameColor,
    this.badges = const [],
    this.profilePictureUrl,
  });

  /// Parses a Kick webhook user object (sender, follower, subscriber, ...).
  factory KickUserModel.fromJson(Map<String, dynamic> json) {
    final identity = json['identity'];
    final username = json['username'] as String? ?? '';
    return KickUserModel(
      userId: json['user_id']?.toString() ?? '',
      login: (json['channel_slug'] as String?) ?? username.toLowerCase(),
      displayName: username.isEmpty ? null : username,
      usernameColor: identity?['username_color'],
      badges: [
        for (final badge in (identity?['badges'] as List?) ?? const [])
          KickBadge.fromJson(Map<String, dynamic>.from(badge)),
      ],
      profilePictureUrl:
          (json['profile_picture'] as String?)?.isNotEmpty == true
              ? json['profile_picture']
              : null,
    );
  }

  @override
  String get provider => Providers.kick;

  @override
  bool get isBot => _bots.contains(login.toLowerCase());

  bool hasBadge(String type) => badges.any((badge) => badge.type == type);

  Color? get color {
    final hex = usernameColor;
    if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) {
      return null;
    }
    return Color(int.parse("ff${hex.substring(1)}", radix: 16));
  }

  @override
  bool operator ==(other) => other is KickUserModel && other.userId == userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => login;
}

const _bots = {"botrix", "kickbot", "streamelements", "nightbot"};
