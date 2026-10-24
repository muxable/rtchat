import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/qr_code.dart';

/// The page [channel] streams on.
Uri channelUrl(Channel channel) {
  switch (channel.provider) {
    case Providers.kick:
      return Uri.https('kick.com', '/${channel.displayName}');
  }
  return Uri.https('www.twitch.tv', '/${channel.displayName}');
}

/// A QR code linking to [account]'s channel.
class QRDisplay extends StatelessWidget {
  final Account account;

  const QRDisplay({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;

    final channel = account.channel;
    final inviteLink = channelUrl(channel).toString();

    return Selector<QRModel, VoidCallback>(
      selector: (_, qrModel) => qrModel.changeGradient,
      builder: (context, changeGradient, _) {
        return GestureDetector(
          onTap: changeGradient,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: size.height * 0.03),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: size.height * 0.02,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      QrImageView(
                        data: inviteLink,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                      CircleAvatar(
                        radius: isLandscape ? 25 : 30,
                        backgroundImage: channel.profilePicture,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: size.height * 0.01),
                child: Text(
                  '/${channel.displayName}',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
