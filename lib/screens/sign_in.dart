import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/user.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

final url = Uri.https('chat.rtirl.com', '/auth/twitch/redirect');

class SignInScreen extends StatelessWidget {
  final bool loading;

  SignInScreen({Key? key, required this.loading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image(width: 160, image: AssetImage('assets/logo.png')),
        Text("RealtimeChat",
            style: Theme.of(context)
                .textTheme
                .headline6!
                .copyWith(color: Colors.white)),
      ]);
    }
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Image(width: 160, image: AssetImage('assets/logo.png')),
      Padding(
          padding: EdgeInsets.only(bottom: 64),
          child: Text("RealtimeChat",
              style: Theme.of(context)
                  .textTheme
                  .headline6!
                  .copyWith(color: Colors.white))),
      Container(
        width: 400,
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 64),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Color(0xFF6441A5)),
              ),
              child: Consumer<UserModel>(builder: (context, user, child) {
                return Text("Sign in with Twitch");
              }),
              onPressed: () async {
                final user = Provider.of<UserModel>(context, listen: false);
                if (user.isSignedIn()) {
                  user.signOut();
                } else {
                  final result = await FlutterWebAuth.authenticate(
                      url: url.toString(), callbackUrlScheme: "com.rtirl.chat");
                  final token = Uri.parse(result).queryParameters['token'];
                  if (token != null) {
                    user.signIn(token);
                  } else {
                    print("uh oh");
                  }
                }
              },
            )),
      ),
    ]);
  }
}
