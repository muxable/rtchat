import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/twitch/badge.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/screens/home.dart';
import 'package:rtchat/screens/settings.dart';
import 'package:rtchat/screens/sign_in.dart';
import 'package:rtchat/screens/twitch/badges.dart';
import 'package:shared_preferences/shared_preferences.dart';

MaterialColor generateMaterialColor(Color color) {
  return MaterialColor(color.value, {
    50: tintColor(color, 0.5),
    100: tintColor(color, 0.4),
    200: tintColor(color, 0.3),
    300: tintColor(color, 0.2),
    400: tintColor(color, 0.1),
    500: tintColor(color, 0),
    600: tintColor(color, -0.1),
    700: tintColor(color, -0.2),
    800: tintColor(color, -0.3),
    900: tintColor(color, -0.4),
  });
}

int tintValue(int value, double factor) =>
    max(0, min((value + ((255 - value) * factor)).round(), 255));

Color tintColor(Color color, double factor) => Color.fromRGBO(
    tintValue(color.red, factor),
    tintValue(color.green, factor),
    tintValue(color.blue, factor),
    1);

final primarySwatch = generateMaterialColor(Color(0xFF009FDF));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  if (kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }
  runZonedGuarded(() {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    runApp(App(prefs: prefs));
  }, FirebaseCrashlytics.instance.recordError);
}

class App extends StatelessWidget {
  final SharedPreferences prefs;

  App({required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserModel()),
        ChangeNotifierProvider(create: (context) {
          final model = LayoutModel.fromJson(
              jsonDecode(prefs.getString("layout") ?? "{}"));
          return model
            ..addListener(() {
              prefs.setString('layout', jsonEncode(model.toJson()));
            });
        }),
        ChangeNotifierProxyProvider<UserModel, ChatHistoryModel>(
            create: (context) => ChatHistoryModel(TtsModel()),
            update: (context, user, chatHistory) => (chatHistory == null
                ? ChatHistoryModel(TtsModel())
                : chatHistory)
              ..subscribe(user.channels)),
        ChangeNotifierProxyProvider<UserModel, TwitchBadgeModel>(
            create: (context) {
          final model = TwitchBadgeModel.fromJson(
              jsonDecode(prefs.getString("twitch_badge") ?? "{}"));
          return model
            ..addListener(() {
              prefs.setString('twitch_badge', jsonEncode(model.toJson()));
            });
        }, update: (context, user, twitchBadge) {
          if (twitchBadge == null) {
            final model = TwitchBadgeModel.fromJson(
                jsonDecode(prefs.getString("twitch_badge") ?? "{}"));
            return model
              ..addListener(() {
                prefs.setString('twitch_badge', jsonEncode(model.toJson()));
              })
              ..bind(user.channels);
          }
          return twitchBadge..bind(user.channels);
        }),
      ],
      child: MaterialApp(
        title: 'RealtimeChat',
        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: primarySwatch,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: primarySwatch,
          scaffoldBackgroundColor: Colors.black,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) {
            return Consumer<UserModel>(builder: (context, model, child) {
              if (!model.isSignedIn()) {
                return SignInScreen();
              }
              return HomeScreen();
            });
          },
          '/settings': (context) => SettingsScreen(),
          '/settings/badges': (context) => TwitchBadgesScreen(),
        },
      ),
    );
  }
}
