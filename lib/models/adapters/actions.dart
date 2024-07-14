import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:rtchat/models/channels.dart';
import 'package:http/http.dart' as http;

class ActionsAdapter {
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;
  final FirebaseAuth auth;

  ActionsAdapter._(
      {required this.firestore, required this.functions, required this.auth});

  static ActionsAdapter get instance => _instance ??= ActionsAdapter._(
      firestore: FirebaseFirestore.instance,
      functions: FirebaseFunctions.instance,
      auth: FirebaseAuth.instance);
  static ActionsAdapter? _instance;

  Future<String?> send(Channel channel, String message) async {
    final call = functions.httpsCallable('send');
    final key = firestore.collection('actions').doc().id;
    for (var i = 0; i < 3; i++) {
      try {
        final result = await call({
          "id": key,
          "provider": channel.provider,
          "channelId": channel.channelId,
          "message": message,
        });
        return result.data;
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      }
    }
    throw Exception("Failed to send message");
  }

  Future<void> ban(Channel channel, String username) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }
    final tokenDoc = await firestore.collection('tokens').doc(user.uid).get();
    final token = tokenDoc.data()?['twitch']['access_token'];
    if (token == null) {
      throw Exception("Failed to retrieve auth token");
    }
    final response = await http.post(
      Uri.parse('https://api.twitch.tv/helix/moderation/bans'),
      headers: {
        'Authorization': 'Bearer $token',
        'Client-Id': 'your-client-id',
        'Content-Type': 'application/json',
      },
      body: {
        'broadcaster_id': channel.channelId,
        'moderator_id': user.uid,
        'user_id': username,
      },
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to ban user");
    }
  }

  Future<void> unban(Channel channel, String username) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }
    final tokenDoc = await firestore.collection('tokens').doc(user.uid).get();
    final token = tokenDoc.data()?['twitch']['access_token'];
    if (token == null) {
      throw Exception("Failed to retrieve auth token");
    }
    final response = await http.delete(
      Uri.parse('https://api.twitch.tv/helix/moderation/bans'),
      headers: {
        'Authorization': 'Bearer $token',
        'Client-Id': 'your-client-id',
        'Content-Type': 'application/json',
      },
      body: {
        'broadcaster_id': channel.channelId,
        'moderator_id': user.uid,
        'user_id': username,
      },
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to unban user");
    }
  }

  Future<void> timeout(Channel channel, String username, String reason,
      Duration duration) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }
    final tokenDoc = await firestore.collection('tokens').doc(user.uid).get();
    final token = tokenDoc.data()?['twitch']['access_token'];
    if (token == null) {
      throw Exception("Failed to retrieve auth token");
    }
    final response = await http.post(
      Uri.parse('https://api.twitch.tv/helix/moderation/bans'),
      headers: {
        'Authorization': 'Bearer $token',
        'Client-Id': 'your-client-id',
        'Content-Type': 'application/json',
      },
      body: {
        'broadcaster_id': channel.channelId,
        'moderator_id': user.uid,
        'user_id': username,
        'duration': duration.inSeconds.toString(),
        'reason': reason,
      },
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to timeout user");
    }
  }

  Future<void> delete(Channel channel, String messageId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }
    final tokenDoc = await firestore.collection('tokens').doc(user.uid).get();
    final token = tokenDoc.data()?['twitch']['access_token'];
    if (token == null) {
      throw Exception("Failed to retrieve auth token");
    }
    final response = await http.delete(
      Uri.parse('https://api.twitch.tv/helix/moderation/chat'),
      headers: {
        'Authorization': 'Bearer $token',
        'Client-Id': 'your-client-id',
        'Content-Type': 'application/json',
      },
      body: {
        'broadcaster_id': channel.channelId,
        'moderator_id': user.uid,
        'message_id': messageId,
      },
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to delete message");
    }
  }

  Future<void> raid(Channel fromChannel, Channel toChannel) async {
    if (fromChannel.provider != toChannel.provider) {
      throw ArgumentError(
          "Cannot raid between channels of different providers");
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not authenticated");
    }
    final tokenDoc = await firestore.collection('tokens').doc(user.uid).get();
    final token = tokenDoc.data()?['twitch']['access_token'];
    if (token == null) {
      throw Exception("Failed to retrieve auth token");
    }
    final response = await http.post(
      Uri.parse('https://api.twitch.tv/helix/raids'),
      headers: {
        'Authorization': 'Bearer $token',
        'Client-Id': 'your-client-id',
        'Content-Type': 'application/json',
      },
      body: {
        'from_broadcaster_id': fromChannel.channelId,
        'to_broadcaster_id': toChannel.channelId,
      },
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to raid channel");
    }
  }
}
