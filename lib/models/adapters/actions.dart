import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rtchat/models/channels.dart';

class ActionsAdapter {
  final FirebaseFunctions functions;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ActionsAdapter._(
      {required this.functions, required this.firestore, required this.auth});

  static ActionsAdapter get instance => _instance ??= ActionsAdapter._(
        functions: FirebaseFunctions.instance,
        firestore: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
      );
  static ActionsAdapter? _instance;

  Future<String?> send(Channel channel, String message) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      return null;
    }
    final ref = await firestore
        .collection("channels")
        .doc(channel.toString())
        .collection("actions")
        .add({
      "userId": userId,
      "message": message,
      "createdAt": FieldValue.serverTimestamp(),
    });
    // listen on the document for isComplete.
    final snapshot = await ref
        .snapshots()
        .firstWhere((snapshot) => snapshot.get("isComplete") == true);
    return snapshot.get("error");
  }

  Future<void> ban(Channel channel, String username) async {
    final call = functions.httpsCallable('ban');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
    });
  }

  Future<void> unban(Channel channel, String username) async {
    final call = functions.httpsCallable('unban');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
    });
  }

  Future<void> timeout(Channel channel, String username, String reason,
      Duration duration) async {
    final call = functions.httpsCallable('timeout');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
      "reason": reason,
      "length": duration.inSeconds,
    });
  }

  Future<void> delete(Channel channel, String messageId) async {
    final call = functions.httpsCallable('deleteMessage');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "messageId": messageId,
    });
  }
}
