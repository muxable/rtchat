import 'package:flutter/painting.dart';
import 'package:rtchat/models/channels.dart';

const colors = [
  Color(0xFFFF0000),
  Color(0xFF0000FF),
  Color(0xFF00FF00),
  Color(0xFFB22222),
  Color(0xFFFF7F50),
  Color(0xFF9ACD32),
  Color(0xFFFF4500),
  Color(0xFF2E8B57),
  Color(0xFFDAA520),
  Color(0xFFD2691E),
  Color(0xFF5F9EA0),
  Color(0xFF1E90FF),
  Color(0xFFFF69B4),
  Color(0xFF8A2BE2),
  Color(0xFF00FF7F),
];

const botList = {
  'streamlab',
  'streamlabs',
  'nightbot',
  'xanbot',
  'ankhbot',
  'moobot',
  'wizebot',
  'phantombot',
  'streamelements',
  'streamelement'
};

class TwitchUserModel {
  final String userId;
  final String? displayName;
  final String login;

  const TwitchUserModel(
      {required this.userId, this.displayName, required this.login});

  @override
  String toString() => login;

  @override
  int get hashCode => login.hashCode;

  @override
  bool operator ==(other) =>
      other is TwitchUserModel &&
      other.userId == userId &&
      other.displayName == displayName &&
      other.login == login;

  bool get isBot => botList.contains(login.toLowerCase());

  String get display {
    final author = displayName ?? login;
    if (author.toLowerCase() != login) {
      // this is an internationalized name.
      return "$displayName ($login)";
    }
    return author;
  }

  Color get color {
    final n = display.codeUnits.first + display.codeUnits.last;
    return colors[n % colors.length];
  }

  Uri get profilePictureUrl {
    return Uri.parse(
        "https://rtirl.com/pfp.png?provider=twitch&channelId=$userId");
  }

  Channel get asChannel => Channel("twitch", userId, displayName ?? login);

  TwitchUserModel.fromJson(Map<String, dynamic> json)
      : userId = json["userId"],
        displayName = json["displayName"],
        login = json["login"];

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "displayName": displayName,
        "login": login,
      };
}
