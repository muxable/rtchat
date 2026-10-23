import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/firebase_options.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/channels.dart';

/// The Android emulator reaches the host machine's loopback via 10.0.2.2.
final emulatorHost = Platform.isAndroid ? '10.0.2.2' : 'localhost';

const _firestorePort = 8080;

/// Where `CallableStub` (callable_stub.dart) listens. It runs in the test's
/// own process, which on Android is on the device, so unlike the emulators
/// it's reached on the device's loopback.
const callableHost = '127.0.0.1';
const callablePort = 5999;

/// Sends [app]'s callables to `CallableStub`.
void _useCallableStub(FirebaseApp app) {
  Api.forApp(app).useEmulator(callableHost, callablePort);
  // Api maps the loopback to the host machine on Android, as the emulators
  // run there. Point the same FirebaseFunctions at the device's own instead.
  FirebaseFunctions.instanceFor(app: app).useFunctionsEmulator(
    callableHost,
    callablePort,
    automaticHostMapping: false,
  );
}

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
    _useCallableStub(app);
  }
  FirebaseDatabase.instance.useDatabaseEmulator(emulatorHost, 9000);
  // Functions are not emulated. Callables go to CallableStub instead, or
  // fail fast while it isn't running, rather than reaching production.
  _useCallableStub(Firebase.app());
}

/// Signs out of [DEFAULT] and every account slot.
Future<void> signOutEverywhere() async {
  await FirebaseAuth.instance.signOut();
  for (final provider in Providers.all) {
    await FirebaseAuth.instanceFor(
      app: Firebase.app(accountAppName(provider)),
    ).signOut();
  }
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
