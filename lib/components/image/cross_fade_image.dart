import 'package:flutter/material.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';

class CrossFadeImage extends StatelessWidget {
  const CrossFadeImage({
    Key? key,
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
  }) : super(key: key);

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
              image: placeholder!, errorBuilder: placeholderErrorBuilder),
          secondChild: child,
          crossFadeState: frame == null
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
