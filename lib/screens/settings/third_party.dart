import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/adapters/donations.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/urls.dart';

const streamlabsCurrencies = [
  [null, "Donation's currency"],
  ['AUD', 'Australian Dollar'],
  ['BRL', 'Brazilian Real'],
  ['CAD', 'Canadian Dollar'],
  ['CZK', 'Czech Koruna'],
  ['DKK', 'Danish Krone'],
  ['EUR', 'Euro'],
  ['HKD', 'Hong Kong Dollar'],
  ['ILS', 'Israeli New Sheqel'],
  ['MYR', 'Malaysian Ringgit'],
  ['MXN', 'Mexican Peso'],
  ['NOK', 'Norwegian Krone'],
  ['NZD', 'New Zealand Dollar'],
  ['PHP', 'Philippine Peso'],
  ['PLN', 'Polish Zloty'],
  ['GBP', 'Pound Sterling'],
  ['RUB', 'Russian Ruble'],
  ['SGD', 'Singapore Dollar'],
  ['SEK', 'Swedish Krona'],
  ['CHF', 'Swiss Franc'],
  ['THB', 'Thai Baht'],
  ['TRY', 'Turkish Lira'],
  ['USD', 'US Dollar']
];

class _RealtimeCashWidget extends StatelessWidget {
  final String userId;

  const _RealtimeCashWidget({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: DonationsAdapter.instance.forRealtimeChatAddress(userId: userId),
      builder: (context, snapshot) {
        return Column(children: [
          ListTile(
            leading: const Image(image: AssetImage('assets/realtimecash.png')),
            title: const Text("RealtimeCash"),
            subtitle: const Text("Connect an ETH or MATIC wallet"),
            trailing: SizedBox(
              width: 24,
              height: 24,
              child: snapshot.data != null
                  ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    )
                  : const Icon(Icons.help),
            ),
            // open https://cash.rtirl.com/
            onTap: () => openUrl(Uri.parse("https://cash.rtirl.com/")),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 88, right: 16),
            child: TextField(
                controller: TextEditingController()..text = snapshot.data ?? "",
                readOnly: true,
                decoration: InputDecoration(
                    hintText: "Wallet address",
                    suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () {
                          showModalBottomSheet<void>(
                              context: context,
                              builder: (context) {
                                return MobileScanner(
                                    allowDuplicates: false,
                                    onDetect: (barcode, args) {
                                      final value = barcode.rawValue;
                                      if (value != null) {
                                        DonationsAdapter.instance
                                            .setRealtimeCashAddress(
                                                address: value.toLowerCase());
                                      }
                                      Navigator.of(context).pop();
                                    });
                              });
                        })),
                keyboardType: TextInputType.url),
          ),
        ]);
      },
    );
  }
}

class _StreamlabsWidget extends StatelessWidget {
  final String userId;

  const _StreamlabsWidget({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Image(image: AssetImage('assets/streamlabs.png')),
      trailing: SizedBox(
        width: 24,
        height: 24,
        child: StreamBuilder(
          stream: DonationsAdapter.instance.forStreamlabsConfig(userId: userId),
          builder: (context, snapshot) {
            return snapshot.data != null
                ? const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  )
                : Container();
          },
        ),
      ),
      title: const Text("Streamlabs"),
      subtitle: const Text("See your Streamlabs donations"),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final userModel = Provider.of<UserModel>(context, listen: false);
        final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
        final provider = userModel.userChannel?.provider;
        if (provider == null) {
          messenger.showSnackBar(const SnackBar(
              content: Text(
                  "Some strange authentication error occurred. Try signing out, or ask on Discord?")));
          return;
        }
        final result = await FlutterWebAuth.authenticate(
            url:
                "https://chat.rtirl.com/auth/streamlabs/redirect?token=$idToken&provider=$provider",
            callbackUrlScheme: "com.rtirl.chat");
        final token = Uri.parse(result).queryParameters['token'];
        if (token == null) {
          messenger.showSnackBar(const SnackBar(
            content:
                Text("Hmm, that didn't work. Try again, or ask on Discord?"),
          ));
        }
      },
    );
  }
}

class ThirdPartyScreen extends StatelessWidget {
  const ThirdPartyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Third-party services")),
        body: Consumer<UserModel>(
          builder: (context, userModel, child) {
            final userId = userModel.user?.uid;
            if (userId == null) {
              // the user should be signed in at this point.
              return Container();
            }
            return ListView(
              children: [
                _RealtimeCashWidget(userId: userId),
                const Divider(),
                _StreamlabsWidget(userId: userId),
              ],
            );
          },
        ));
  }
}
