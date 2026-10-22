import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/components/scanner_error.dart';
import 'package:rtchat/components/scanner_settings.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/adapters/donations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/models/wallet_address.dart';
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
  ['USD', 'US Dollar'],
];

/// Opens [url] to sign in to a service, returning the URL it redirects back
/// to.
typedef Authenticate = Future<String> Function(Uri url);

Future<String> _authenticate(Uri url) => FlutterWebAuth2.authenticate(
  url: url.toString(),
  callbackUrlScheme: "com.rtirl.chat",
);

/// Connects [service] to [account]. The ID token says which account it's
/// for, so the backend stores it under that account's uid.
Future<void> _connect(
  BuildContext context,
  Account account,
  String service,
  Authenticate authenticate,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  final idToken = await account.user.getIdToken();
  if (idToken == null) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          "Some strange authentication error occurred. Try signing out, or ask on Discord?",
        ),
      ),
    );
    return;
  }
  final result = await authenticate(
    Uri.https("chat.rtirl.com", "/auth/$service/redirect", {
      "token": idToken,
      "provider": account.provider,
    }),
  );
  final token = Uri.parse(result).queryParameters['token'];
  if (token == null) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.thirdPartyAuthError)));
  }
}

class _RealtimeCashWidget extends StatefulWidget {
  final Account account;
  final DonationsAdapter donations;

  const _RealtimeCashWidget({
    super.key,
    required this.account,
    required this.donations,
  });

  @override
  State<_RealtimeCashWidget> createState() => _RealtimeCashWidgetState();
}

class _RealtimeCashWidgetState extends State<_RealtimeCashWidget> {
  var _scanController = MobileScannerController(
    // facing: CameraFacing.back,
    // torchEnabled: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: widget.donations.forRealtimeChatAddress(
        userId: widget.account.user.uid,
      ),
      builder: (context, snapshot) {
        return Column(
          children: [
            ListTile(
              leading: const Image(
                image: AssetImage('assets/realtimecash.png'),
              ),
              title: const Text("RealtimeCash"),
              subtitle: Text(
                AppLocalizations.of(context)!.realtimeCashSubtitle,
              ),
              trailing: SizedBox(
                width: 24,
                height: 24,
                child:
                    snapshot.data != null
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.help),
              ),
              // open https://cash.rtirl.com/
              onTap: () => openUrl(Uri.parse("https://cash.rtirl.com/")),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 88, right: 16),
              child: TextField(
                controller: TextEditingController()..text = snapshot.data ?? "",
                readOnly: false,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.walletAddress,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () {
                      final messenger = ScaffoldMessenger.of(context);

                      showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        builder: (ctx) {
                          return Stack(
                            children: [
                              MobileScanner(
                                errorBuilder: (context, error) {
                                  return ScannerErrorWidget(error: error);
                                },
                                controller: _scanController,
                                onDetect: (capture) {
                                  final address = parseWalletAddress(
                                    capture.barcodes.firstOrNull?.rawValue,
                                  );
                                  if (address == null) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.invalidUrlErrorText,
                                        ),
                                      ),
                                    );
                                  } else {
                                    widget.donations.setRealtimeCashAddress(
                                      address: address,
                                    );
                                  }
                                  Navigator.pop(ctx);
                                },
                              ),
                              Positioned(
                                top: 50,
                                left: 0,
                                right: 0,
                                child: ScannerSettings(
                                  scanController: _scanController,
                                ),
                              ),
                            ],
                          );
                        },
                      ).then((value) {
                        _scanController.dispose();

                        _scanController = MobileScannerController(
                          detectionSpeed: DetectionSpeed.noDuplicates,
                        );
                      });
                    },
                  ),
                ),
                keyboardType: TextInputType.url,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StreamlabsWidget extends StatelessWidget {
  final Account account;
  final DonationsAdapter donations;
  final Authenticate authenticate;

  const _StreamlabsWidget({
    required this.account,
    required this.donations,
    required this.authenticate,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Image(image: AssetImage('assets/streamlabs.png')),
      trailing: SizedBox(
        width: 24,
        height: 24,
        child: StreamBuilder(
          stream: donations.forStreamlabsConfig(userId: account.user.uid),
          builder: (context, snapshot) {
            return snapshot.data != null
                ? const Icon(Icons.check_circle, color: Colors.green)
                : Container();
          },
        ),
      ),
      title: const Text("Streamlabs"),
      subtitle: Text(AppLocalizations.of(context)!.streamlabsSubtitle),
      onTap: () => _connect(context, account, "streamlabs", authenticate),
    );
  }
}

class _StreamElementsWidget extends StatelessWidget {
  final Account account;
  final DonationsAdapter donations;
  final Authenticate authenticate;

  const _StreamElementsWidget({
    required this.account,
    required this.donations,
    required this.authenticate,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Image(image: AssetImage('assets/streamelements.png')),
      trailing: SizedBox(
        width: 24,
        height: 24,
        child: StreamBuilder(
          stream: donations.forStreamElementsConfig(userId: account.user.uid),
          builder: (context, snapshot) {
            return snapshot.data != null
                ? const Icon(Icons.check_circle, color: Colors.green)
                : Container();
          },
        ),
      ),
      title: const Text("StreamElements"),
      subtitle: Text(AppLocalizations.of(context)!.streamElementsSubtitle),
      onTap: () => _connect(context, account, "streamelements", authenticate),
    );
  }
}

class _RealTimeKitWidget extends StatefulWidget {
  @override
  State<_RealTimeKitWidget> createState() => _RealTimeKitWidgetState();
}

class _RealTimeKitWidgetState extends State<_RealTimeKitWidget> {
  var _scanController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  String apiKey = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Image(image: AssetImage('assets/realtimekit.png')),
          title: const Text("RealtimeKit"),
          subtitle: const Text("Control OBS remotely"),
          trailing: SizedBox(
            width: 24,
            height: 24,
            child:
                apiKey.isNotEmpty
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.help),
          ),
          onTap:
              () =>
                  apiKey.isNotEmpty
                      ? openUrl(Uri.parse(apiKey))
                      : openUrl(Uri.parse("https://kit.rtirl.com/")),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 88, right: 16),
          child: TextField(
            controller: TextEditingController()..text = apiKey,
            readOnly: false,
            decoration: InputDecoration(
              hintText: "API Key",
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);

                  showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    builder: (ctx) {
                      return Stack(
                        children: [
                          MobileScanner(
                            errorBuilder: (context, error) {
                              return ScannerErrorWidget(error: error);
                            },
                            controller: _scanController,
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;

                              if (barcodes.isEmpty) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.invalidUrlErrorText,
                                    ),
                                  ),
                                );
                                return;
                              }

                              final barcode = barcodes.first;

                              if (barcode.rawValue == null ||
                                  barcode.rawValue!.isEmpty) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.invalidUrlErrorText,
                                    ),
                                  ),
                                );
                                Navigator.pop(ctx);
                                return;
                              }

                              setState(() {
                                apiKey = barcode.rawValue!;
                              });

                              Navigator.pop(ctx);
                            },
                          ),
                          Positioned(
                            top: 50,
                            left: 0,
                            right: 0,
                            child: ScannerSettings(
                              scanController: _scanController,
                            ),
                          ),
                        ],
                      );
                    },
                  ).then((value) {
                    _scanController.dispose();

                    _scanController = MobileScannerController(
                      detectionSpeed: DetectionSpeed.noDuplicates,
                    );
                  });
                },
              ),
            ),
            keyboardType: TextInputType.url,
          ),
        ),
      ],
    );
  }
}

/// Names the account the connections after it belong to.
class _AccountHeader extends StatelessWidget {
  final Account account;

  const _AccountHeader(this.account);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ProviderIcon(account.provider),
      title: Text(
        account.channel.displayName,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(providerName(account.provider)),
    );
  }
}

class ThirdPartyScreen extends StatelessWidget {
  /// Reads and writes an account's connections.
  final DonationsAdapter Function(Account account) donations;

  /// Opens a service's sign in page.
  final Authenticate authenticate;

  const ThirdPartyScreen({
    super.key,
    @visibleForTesting this.donations = DonationsAdapter.forAccount,
    @visibleForTesting this.authenticate = _authenticate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.thirdPartyServices),
      ),
      body: Consumer<UserModel>(
        builder: (context, userModel, child) {
          final accounts = userModel.accounts;
          // connections are each account's own, so each account gets its
          // own section once there's more than one.
          return ListView(
            children: [
              for (final account in accounts) ...[
                if (accounts.length > 1) _AccountHeader(account),
                _RealtimeCashWidget(
                  key: ValueKey(account.app.name),
                  account: account,
                  donations: donations(account),
                ),
                const Divider(),
                _StreamlabsWidget(
                  account: account,
                  donations: donations(account),
                  authenticate: authenticate,
                ),
                const Divider(),
                _StreamElementsWidget(
                  account: account,
                  donations: donations(account),
                  authenticate: authenticate,
                ),
                const Divider(),
              ],
              _RealTimeKitWidget(),
            ],
          );
        },
      ),
    );
  }
}
