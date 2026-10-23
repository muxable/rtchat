# System speech adapters

The Android and iOS `SystemTtsPlugin` files are adapted from
[flutter_tts 4.2.5](https://pub.dev/packages/flutter_tts/versions/4.2.5).
They retain the upstream MIT license in `LICENSE` (also included in the
package license for Flutter's license bundle).

Local changes rename the class/package and method channel, and register the
adapters through `OnDeviceTtsPlugin`. `SystemTtsPlatform` exposes only the
operations used by `SystemTtsEngine`; Android still synthesizes into a file
and plays it in-process with `just_audio`.
