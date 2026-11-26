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
    this.animate = true,
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

  /// Whether animated images should play.
  /// Defaults to true to preserve existing behavior.
  final bool animate;

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
    // Static mode: decode and retain only the first frame.
    if (!animate) {
      return _FirstFrameImage(
        image: image,
        placeholder: placeholder,
        placeholderErrorBuilder: placeholderErrorBuilder,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        matchTextDirection: matchTextDirection,
      );
    }

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
    return _image(
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
  }
}

/// Displays only the first frame of an image, without continuing to listen
/// for animation frames.
class _FirstFrameImage extends StatefulWidget {
  const _FirstFrameImage({
    required this.image,
    this.placeholder,
    this.placeholderErrorBuilder,
    this.width,
    this.height,
    this.fit,
    required this.alignment,
    required this.repeat,
    required this.matchTextDirection,
  });

  final ImageProvider image;
  final ImageProvider? placeholder;
  final ImageErrorWidgetBuilder? placeholderErrorBuilder;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final bool matchTextDirection;

  @override
  State<_FirstFrameImage> createState() => _FirstFrameImageState();
}

class _FirstFrameImageState extends State<_FirstFrameImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;

  ImageInfo? _firstFrame;
  bool _hasError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant _FirstFrameImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.image != widget.image) {
      _loadImage();
    }
  }

  void _loadImage() {
    _removeListener();
    _firstFrame?.dispose();
    _firstFrame = null;
    _hasError = false;

    final configuration = createLocalImageConfiguration(context);
    final stream = widget.image.resolve(configuration);

    _stream = stream;

    late final ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (!mounted) {
          info.dispose();
          return;
        }

        // Keep our own reference to the first frame.
        final firstFrame = ImageInfo(
          image: info.image.clone(),
          scale: info.scale,
        );

        // Stop receiving subsequent animation frames.
        _stream?.removeListener(listener);
        _listener = null;

        info.dispose();

        setState(() {
          _firstFrame?.dispose();
          _firstFrame = firstFrame;
          _hasError = false;
        });
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!mounted) return;

        _removeListener();

        setState(() {
          _hasError = true;
        });
      },
    );

    _listener = listener;
    stream.addListener(listener);
  }

  void _removeListener() {
    final stream = _stream;
    final listener = _listener;

    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }

    _listener = null;
    _stream = null;
  }

  @override
  void dispose() {
    _removeListener();
    _firstFrame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _firstFrame;

    if (frame != null) {
      return RawImage(
        image: frame.image,
        scale: frame.scale,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        repeat: widget.repeat,
        matchTextDirection: widget.matchTextDirection,
      );
    }

    if (widget.placeholder != null) {
      return Image(
        image: widget.placeholder!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        repeat: widget.repeat,
        matchTextDirection: widget.matchTextDirection,
        errorBuilder: widget.placeholderErrorBuilder,
        excludeFromSemantics: true,
      );
    }

    if (_hasError) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Icon(Icons.broken_image),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
    );
  }
}
