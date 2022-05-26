# muxable/rtchat/pinnable

This directory contains the UI elements that render chat history efficiently. It is based off of Flutter's ScrollView but allows individual messages to be pinned to the top.

## Looking for practice?

This element is a very good introduction into how Flutter's rendering pipeline works. If you would like to learn more about the depths of Flutter, consider deleting `scroll_view.dart` and `viewport.dart` and writing them from scratch.

Relevant documentation to help you out can be found on docs.flutter.dev: https://docs.flutter.dev/resources/architectural-overview#layout-and-rendering

The implementation is similar to Flutter's ScrollView: https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/widgets/scroll_view.dart

Start by extending `ScrollView` and implement the single public API:

```dart
PinnableMessageScrollView(
    vsync: this,
    controller: _controller,  // ScrollController()
    itemBuilder: (index) => StyleModelTheme(
    child: ChatHistoryMessage(
        message: messages[index], channel: widget.channel),
    ),
    isPinnedBuilder: (index) {
        final expiration = expirations[index];
        if (expiration != null) {
            return expiration.isAfter(now);
        }
        return false;
    },
    count: messages.length,
);
```
