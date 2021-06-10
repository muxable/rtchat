import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/activity_feed.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/twitch/badge.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/screens/activity_feed.dart';
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
        ChangeNotifierProxyProvider<UserModel, LayoutModel>(create: (context) {
          final model = LayoutModel.fromJson(
              jsonDecode(prefs.getString("layout") ?? "{}"));
          return model
            ..addListener(() {
              prefs.setString('layout', jsonEncode(model.toJson()));
            });
        }, update: (context, user, layout) {
          final userChannel = user.userChannel;
          layout?.channels = userChannel == null ? {} : {userChannel};
          user.addListener(() {
            final userChannel = user.userChannel;
            layout?.channels = userChannel == null ? {} : {userChannel};
          });
          return layout!;
        }),
        ChangeNotifierProxyProvider<LayoutModel, ChatHistoryModel>(
            create: (context) => ChatHistoryModel(TtsModel()),
            update: (context, layout, chatHistory) =>
                chatHistory!..subscribe(layout.channels)),
        ChangeNotifierProxyProvider<LayoutModel, ActivityFeedModel>(
            create: (context) {
              final model = ActivityFeedModel.fromJson(
                  jsonDecode(prefs.getString("activity_feed") ?? "{}"));
              return model
                ..addListener(() {
                  prefs.setString("activity_feed", jsonEncode(model.toJson()));
                });
            },
            update: (context, layout, activityFeed) =>
                activityFeed!..bind(layout)),
        ChangeNotifierProxyProvider<LayoutModel, TwitchBadgeModel>(
          create: (context) {
            final model = TwitchBadgeModel.fromJson(
                jsonDecode(prefs.getString("twitch_badge") ?? "{}"));
            model.addListener(() {
              prefs.setString('twitch_badge', jsonEncode(model.toJson()));
            });
            return model;
          },
          update: (context, layout, twitchBadge) {
            return twitchBadge!..bind(layout.channels);
          },
        ),
      ],
      child: DefaultTabController(
        initialIndex: 0,
        length: 2,
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
            '/settings/activity-feed': (context) => ActivityFeedScreen(),
          },
        ),
      ),
    );
  }
}
