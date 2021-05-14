import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

final validateUrl = Uri.https('id.twitch.tv', '/oauth2/validate');

const TWITCH_CLIENT_ID = "edfnh2q85za8phifif9jxt3ey6t9b9";

class TwitchUserModel extends ChangeNotifier {
  String? _token;
  String? _username;

  Future<void> setToken(String token) async {
    _token = token;

    final response =
        await http.get(validateUrl, headers: {"Authorization": "OAuth $token"});
    final body = jsonDecode(response.body);
    if (body['client_id'] != TWITCH_CLIENT_ID) {
      await clearToken();
      return;
    }
    _username = body['login'];
    notifyListeners();
  }

  Future<void> clearToken() async {
    _token = null;
    _username = null;
    notifyListeners();
  }

  bool isSignedIn() {
    return _token != null;
  }

  Future<void> send(String message) async {
    final send = FirebaseFunctions.instance.httpsCallable('send');
    final results = await send({
      "provider": "twitch",
      "channel": _username,
      "message": message,
      "identity": {
        "username": _username,
        "password": "oauth:$_token",
      },
    });
    print(results);
  }

  String? get username {
    return _username;
  }

  TwitchUserModel.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    if (token != null) {
      setToken(token);
    }
  }

  Map<String, dynamic> toJson() => {
        "token": _token,
      };
}
