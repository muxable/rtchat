import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/firebase_options.dart';
import 'package:rtchat/models/accounts.dart';

/// The Android emulator reaches the host machine's loopback via 10.0.2.2.
final emulatorHost = Platform.isAndroid ? '10.0.2.2' : 'localhost';

const _firestorePort = 8080;

String get _projectId => DefaultFirebaseOptions.currentPlatform.projectId;

/// Initializes Firebase against the local emulator suite started by
/// `firebase emulators:exec` (see firebase.json).
Future<void> initializeFirebaseEmulators() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Keep test runs out of production telemetry.
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);

  await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, _firestorePort);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
  // the extra account slots must use the emulators too.
  for (final app in await AccountsModel.initializeApps()) {
    await FirebaseAuth.instanceFor(
      app: app,
    ).useAuthEmulator(emulatorHost, 9099);
    FirebaseFirestore.instanceFor(
      app: app,
    ).useFirestoreEmulator(emulatorHost, _firestorePort);
    Api.forApp(app).useEmulator(emulatorHost, 5999);
  }
  FirebaseDatabase.instance.useDatabaseEmulator(emulatorHost, 9000);
  // Functions are not emulated. Point them at an unused port so callables
  // fail fast instead of reaching production; the app already tolerates
  // failures from getEmotes and subscribe.
  Api.forApp(Firebase.app()).useEmulator(emulatorHost, 5999);
}

/// Seeds Firestore through the emulator's REST API. The `owner` bearer token
/// bypasses security rules, which otherwise deny all client writes.
class FirestoreSeeder {
  final _client = HttpClient();

  Uri _uri(String path, [Map<String, String>? query]) => Uri(
    scheme: 'http',
    host: emulatorHost,
    port: _firestorePort,
    path: path,
    queryParameters: query,
  );

  Future<void> setDocument(String path, Map<String, dynamic> data) async {
    final request = await _client.patchUrl(
      _uri('/v1/projects/$_projectId/databases/(default)/documents/$path'),
    );
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer owner')
      ..contentType = ContentType.json;
    request.write(jsonEncode({'fields': _encodeFields(data)}));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw HttpException('seeding $path failed: ${response.statusCode} $body');
    }
  }

  Future<void> clear() async {
    final request = await _client.deleteUrl(
      _uri('/emulator/v1/projects/$_projectId/databases/(default)/documents'),
    );
    final response = await request.close();
    await response.drain<void>();
  }

  void close() => _client.close();

  static Map<String, dynamic> _encodeFields(Map<String, dynamic> data) =>
      data.map((key, value) => MapEntry(key, _encodeValue(value)));

  static Map<String, dynamic> _encodeValue(dynamic value) {
    if (value == null) {
      return {'nullValue': null};
    } else if (value is bool) {
      return {'booleanValue': value};
    } else if (value is int) {
      return {'integerValue': '$value'};
    } else if (value is double) {
      return {'doubleValue': value};
    } else if (value is String) {
      return {'stringValue': value};
    } else if (value is DateTime) {
      return {'timestampValue': value.toUtc().toIso8601String()};
    } else if (value is List) {
      return {
        'arrayValue': {'values': value.map(_encodeValue).toList()},
      };
    } else if (value is Map<String, dynamic>) {
      return {
        'mapValue': {'fields': _encodeFields(value)},
      };
    }
    throw ArgumentError('unsupported type ${value.runtimeType}');
  }
}
