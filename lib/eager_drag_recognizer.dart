import 'package:flutter/gestures.dart';

// HorizontalDragGestureRecognizer with priority in the gesture arena.
class EagerHorizontalDragRecognizer extends HorizontalDragGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  String get debugDescription => 'eager horizontal drag';
}
