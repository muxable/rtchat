import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// https://github.com/brianegan/transparent_image/blob/master/lib/transparent_image.dart
final kTransparentImage = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
]);

class CrossFadeImage extends StatelessWidget {
  const CrossFadeImage({
    super.key,
    this.placeholder,
    this.placeholderErrorBuilder,
    required this.image,
    this.crossfadeDuration = const Duration(milliseconds: 700),
    this.crossfadeCurve = Curves.easeInOut,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.topCenter,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
  });

  final ImageProvider? placeholder;

  final ImageErrorWidgetBuilder? placeholderErrorBuilder;

  final ImageProvider image;

  final Duration crossfadeDuration;

  final Curve crossfadeCurve;

  final double? width;

  final double? height;

  final BoxFit? fit;

  final AlignmentGeometry alignment;

  final ImageRepeat repeat;

  final bool matchTextDirection;

  Image _image({
    required ImageProvider image,
    ImageErrorWidgetBuilder? errorBuilder,
    ImageFrameBuilder? frameBuilder,
  }) {
    return Image(
      image: image,
      errorBuilder: errorBuilder,
      frameBuilder: frameBuilder,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (placeholder == null) {
      return FadeInImage(
        placeholder: MemoryImage(kTransparentImage),
        image: image,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        matchTextDirection: matchTextDirection,
        excludeFromSemantics: true,
      );
    }
    Widget result = _image(
      image: image,
      errorBuilder: (context, error, stackTrace) {
        return _image(
          image: placeholder!,
          errorBuilder: placeholderErrorBuilder,
        );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedCrossFade(
          firstChild: _image(
            image: placeholder!,
            errorBuilder: placeholderErrorBuilder,
          ),
          secondChild: child,
          crossFadeState:
              frame == null
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
          duration: crossfadeDuration,
          firstCurve: const Threshold(1.0),
          secondCurve: crossfadeCurve,
        );
      },
    );
    return result;
  }
}
