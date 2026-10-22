import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rtchat/models/qr_code.dart';
import 'package:rtchat/models/user.dart';

class QRDisplay extends StatelessWidget {
  const QRDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;

    return Selector<
      UserModel,
      ({String displayName, ImageProvider? profilePicture})
    >(
      selector: (_, userModel) {
        final channel = userModel.userChannel;

        return (
          displayName: channel?.displayName ?? '',
          profilePicture: channel?.profilePicture,
        );
      },
      builder: (context, user, _) {
        final inviteLink = 'https://www.twitch.tv/${user.displayName}';

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
                            backgroundImage: user.profilePicture,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: size.height * 0.01),
                    child: Text(
                      '/${user.displayName}',
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
      },
    );
  }
}
