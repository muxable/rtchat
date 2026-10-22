import 'package:flutter/material.dart';
import 'package:rtchat/models/channels.dart';

/// YouTube's brand red.
const youTubeRed = Color(0xFFFF0000);

/// A small icon identifying a streaming platform.
class ProviderIcon extends StatelessWidget {
  final String provider;
  final double size;

  const ProviderIcon(this.provider, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    switch (provider) {
      case Providers.twitch:
        return Image(
            width: size,
            height: size,
            image: const AssetImage('assets/providers/twitch.png'));
      case Providers.kick:
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF53FC18),
            borderRadius: BorderRadius.circular(size / 5),
          ),
          child: Text("K",
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.7,
                  height: 1)),
        );
      case Providers.youtube:
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: youTubeRed,
            borderRadius: BorderRadius.circular(size / 4),
          ),
          child: Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: size * 0.8),
        );
    }
    return Icon(Icons.public, size: size);
  }
}
