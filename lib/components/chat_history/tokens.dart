import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/urls.dart';

/// Renders a chat message token (text, emote, link, mention) for any provider.
Iterable<InlineSpan> renderToken(
  BuildContext context,
  StyleModel styleModel,
  MessageToken token,
) sync* {
  final linkStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
    color: Theme.of(context).colorScheme.secondary,
  );

  final tagStyleStreamer = TextStyle(
    color:
        Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Colors.black,
    backgroundColor:
        Theme.of(context).brightness == Brightness.light
            ? Colors.black
            : Colors.white,
  );
  //for streamermention

  final tagStyle = TextStyle(
    backgroundColor: Theme.of(context).highlightColor,
  ); //for usermention

  final multiplierStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
    color: Theme.of(context).colorScheme.secondary,
  );

  if (token is TextToken) {
    yield TextSpan(text: token.text);
  } else if (token is EmoteToken) {
    yield WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Tooltip(
        message: token.code,
        preferBelow: false,
        child: Image(
          height: styleModel.fontSize,
          image: ResilientNetworkImage(token.url),
          errorBuilder: (context, error, stackTrace) => Text(token.code),
        ),
      ),
    );
  } else if (token is LinkToken) {
    yield WidgetSpan(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text.rich(
          TextSpan(
            text: token.text,
            style: linkStyle,
            recognizer:
                (TapGestureRecognizer()
                  ..onTap = () async {
                    final model = Provider.of<LayoutModel>(
                      context,
                      listen: false,
                    );
                    if (!model.locked) {
                      await openUrl(token.url);
                    }
                  }),
          ),
        ),
      ),
    );
  } else if (token is UserMentionToken) {
    final userModel = Provider.of<UserModel>(context, listen: false);
    final loginChannel = userModel.userChannel?.displayName;
    if (token.username.toLowerCase() == loginChannel?.toLowerCase()) {
      yield TextSpan(
        // wrap tag with nonbreaking spaces
        text: "\u{00A0}@${token.username}\u{00A0}",
        style: tagStyleStreamer,
      );
    } else {
      yield TextSpan(
        // wrap tag with nonbreaking spaces
        text: "\u{00A0}@${token.username}\u{00A0}",
        style: tagStyle,
      );
    }
  } else if (token is CompactedToken) {
    yield* token.children.expand(
      (child) => renderToken(context, styleModel, child),
    );
    yield TextSpan(text: "×${token.multiplicity}", style: multiplierStyle);
  } else {
    throw Exception("invalid token");
  }
}
