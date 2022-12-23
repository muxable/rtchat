import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/user.dart';

final url = Uri.https('chat.rtirl.com', '/auth/twitch/redirect');

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  var _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Image(width: 160, image: AssetImage('assets/logo.png')),
      Padding(
          padding: const EdgeInsets.only(bottom: 64),
          child: Text("RealtimeChat",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(color: Colors.white))),
      if (_isLoading)
        const CircularProgressIndicator()
      else
        SizedBox(
          width: 400,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(const Color(0xFF6441A5)),
                ),
                child: Consumer<UserModel>(builder: (context, user, child) {
                  return Text(AppLocalizations.of(context)!.signInWithTwitch);
                }),
                onPressed: () async {
                  setState(() => _isLoading = true);
                  final user = Provider.of<UserModel>(context, listen: false);
                  try {
                    await FirebaseAnalytics.instance
                        .logLogin(loginMethod: "twitch");
                    final result = await FlutterWebAuth.authenticate(
                        url: url.toString(),
                        callbackUrlScheme: "com.rtirl.chat");
                    final token = Uri.parse(result).queryParameters['token'];
                    if (token != null) {
                      await user.signIn(token);
                    } else {
                      await FirebaseCrashlytics.instance
                          .log("failed to sign in");
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
              )),
        ),
    ]);
  }
}
