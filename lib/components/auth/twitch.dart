import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/user.dart';

final url = Uri.https('chat.rtirl.com', '/auth/twitch/redirect');

class SignInWithTwitch extends StatelessWidget {
  final void Function()? onStart;
  final void Function()? onComplete;

  const SignInWithTwitch({
    Key? key,
    this.onStart,
    this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(const Color(0xFF6441A5)),
      ),
      child: const Text("Sign in with Twitch"),
      onPressed: () async {
        final user = Provider.of<UserModel>(context, listen: false);
        onStart?.call();
        try {
          await FirebaseAnalytics.instance.logLogin(loginMethod: "twitch");
          final result = await FlutterWebAuth.authenticate(
              url: url.toString(), callbackUrlScheme: "com.rtirl.chat");
          final token = Uri.parse(result).queryParameters['token'];
          if (token != null) {
            await user.signIn(token);
            // there's a bit of lag between the sign in call completing and the
            // ui updating to the homepage. delay the onComplete handler so any
            // loading indicator still shows.
            Timer(const Duration(seconds: 3), () {
              onComplete?.call();
            });
          } else {
            await FirebaseCrashlytics.instance.log("failed to sign in");
            onComplete?.call();
          }
        } catch (e, st) {
          await FirebaseCrashlytics.instance.recordError(e, st);
          onComplete?.call();
        }
      },
    );
  }
}
