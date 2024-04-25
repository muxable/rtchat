import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rtchat/models/adapters/profiles.dart';
import 'package:rtchat/models/user.dart';
import 'package:uuid/uuid.dart';

class CompanionAuthWidget extends StatefulWidget {
  final String provider;

  const CompanionAuthWidget({
    super.key,
    required this.provider,
  });

  @override
  State<CompanionAuthWidget> createState() => _CompanionAuthWidgetState();
}

class _CompanionAuthWidgetState extends State<CompanionAuthWidget> {
  final sessionUuid = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    ProfilesAdapter.instance
        .getCompanionAuthToken(sessionUuid: sessionUuid)
        .then((token) {
      final user = Provider.of<UserModel>(context, listen: false);
      return user.signIn(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, controller) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Text(
                "Your browser is too old to support signing in directly. "
                "Scan this QR code with your phone to sign in on another device.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              QrImageView(
                backgroundColor: Colors.white,
                data:
                    'https://chat.rtirl.com/auth/${widget.provider}/redirect?companion=$sessionUuid',
                version: QrVersions.auto,
                size: 200.0,
              ),
            ]),
          );
        });
  }
}
