import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/user.dart';
import 'package:webview_flutter/webview_flutter.dart';

final url = Uri.https('chat.rtirl.com', '/auth/twitch/redirect');

class SignInScreen extends StatelessWidget {
  final bool loading;

  SignInScreen({Key? key, required this.loading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image(width: 160, image: AssetImage('assets/logo.png')),
        Text("RealtimeChat", style: Theme.of(context).textTheme.headline6),
      ]);
    }
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Image(width: 160, image: AssetImage('assets/logo.png')),
      Padding(
          padding: EdgeInsets.only(bottom: 64),
          child: Text("RealtimeChat",
              style: Theme.of(context).textTheme.headline6)),
      Container(
        width: double.infinity,
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 64),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Color(0xFF6441A5)),
              ),
              child: Consumer<UserModel>(builder: (context, user, child) {
                return Text("Sign in with Twitch");
              }),
              onPressed: () {
                final user = Provider.of<UserModel>(context, listen: false);
                if (user.isSignedIn()) {
                  user.signOut();
                } else {
                  showModalBottomSheet<void>(
                    isScrollControlled: true,
                    enableDrag: false,
                    context: context,
                    builder: (context) {
                      return FractionallySizedBox(
                        heightFactor: 0.8,
                        child: WebView(
                          initialUrl: url.toString(),
                          javascriptMode: JavascriptMode.unrestricted,
                          navigationDelegate: (request) {
                            if (request.url
                                .startsWith("https://chat.rtirl.com/?")) {
                              final uri = Uri.parse(request.url);
                              final token = uri.queryParameters['token'];
                              if (token != null) {
                                user.signIn(token);
                                Navigator.pop(context);
                              } else {
                                print("uh oh");
                              }
                              return NavigationDecision.prevent;
                            }
                            return NavigationDecision.navigate;
                          },
                        ),
                      );
                    },
                  );
                }
              },
            )),
      ),
    ]);
  }
}
