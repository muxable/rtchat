import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/twitch_user.dart';
import 'package:webview_flutter/webview_flutter.dart';

final url = Uri.https('id.twitch.tv', '/oauth2/authorize', {
  'response_type': 'token',
  'client_id': "edfnh2q85za8phifif9jxt3ey6t9b9",
  'redirect_uri': 'https://chat.rtirl.com/oauth2redirect',
  'scope': 'chat:edit chat:read',
  "force_verify": "true",
});

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
              child: Consumer<TwitchUserModel>(builder: (context, user, child) {
                return Text("Sign in with Twitch");
              }),
              onPressed: () {
                final user =
                    Provider.of<TwitchUserModel>(context, listen: false);
                if (user.isSignedIn()) {
                  user.clearToken();
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
                            if (request.url.startsWith(
                                "https://chat.rtirl.com/oauth2redirect")) {
                              final uri = Uri.parse(request.url);
                              final params = Uri.splitQueryString(uri.fragment);
                              final token = params["access_token"];
                              if (token != null) {
                                user.setToken(token);
                              }
                              Navigator.pop(context);
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
