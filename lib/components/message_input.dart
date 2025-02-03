class _MessageInputWidgetState extends State<MessageInputWidget> {
  EmoteTextEditingController? _textEditingController;
  final _chatInputFocusNode = FocusNode();
  var _isEmotePickerVisible = false;
  var _isKeyboardVisible = false;
  late StreamSubscription keyboardSubscription;
  var _emoteIndex = Random().nextInt(_emotes.length);
  final _textSeed = Random().nextDouble();
  final List<String> _pendingSend = [];

  @override
  void initState() {
    super.initState();
    final keyboardVisibilityController = KeyboardVisibilityController();
    _textEditingController = EmoteTextEditingController(widget.emotes);
    keyboardSubscription = keyboardVisibilityController.onChange.listen((visible) {
      setState(() {
        _isKeyboardVisible = visible;
      });
    });

    ShareChannel()
      ..onDataReceived = _handleSharedData
      ..getSharedText().then(_handleSharedData);
  }

  @override
  void didUpdateWidget(MessageInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _textEditingController?.emotes = widget.emotes;
  }

  void _handleSharedData(String sharedData) {
    setState(() {
      _textEditingController?.text = sharedData;
    });
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
    _chatInputFocusNode.dispose();
    _textEditingController?.dispose();
    super.dispose();
  }

  void sendMessage(String value) async {
    value = value.trim();
    if (value.isEmpty) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (value.startsWith('!')) {
      final commandsModel = Provider.of<CommandsModel>(context, listen: false);
      commandsModel.addCommand(Command(value, DateTime.now()));
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _textEditingController?.clear();
    });
    var done = false;
    await Future.wait([
      () async {
        try {
          final error = await ActionsAdapter.instance.send(widget.channel, value);
          if (error != null) {
            messenger.showSnackBar(SnackBar(
              content: Text(error),
            ));
          }
        } catch (e) {
          messenger.showSnackBar(SnackBar(
            content: Text(e.toString()),
          ));
        }
        done = true;
        if (!mounted) {
          return;
        }
        setState(() {
          _pendingSend.remove(value);
        });
      }(),
      () async {
        await Future.delayed(const Duration(seconds: 1));
        if (!done) {
          if (!mounted) {
            return;
          }
          setState(() {
            _pendingSend.add(value);
          });
        }
      }(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._pendingSend.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: Text(e, style: const TextStyle(fontStyle: FontStyle.italic)),
              )),
          if (_isKeyboardVisible)
            Flexible(
              child: AutocompleteWidget(
                controller: _textEditingController,
                onSend: sendMessage,
                channel: widget.channel,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                color: Theme.of(context).splashColor,
              ),
              child: TextField(
                focusNode: _chatInputFocusNode,
                controller: _textEditingController,
                textInputAction: TextInputAction.send,
                maxLines: 6,
                minLines: 1,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  prefixIcon: IconButton(
                    onPressed: () {
                      if (_isEmotePickerVisible) {
                        setState(() => _isEmotePickerVisible = false);
                        _chatInputFocusNode.requestFocus();
                      } else {
                        _chatInputFocusNode.unfocus();
                        setState(() {
                          _isEmotePickerVisible = true;
                          _emoteIndex = Random().nextInt(_emotes.length);
                        });
                      }
                    },
                    splashRadius: 24,
                    icon: _isEmotePickerVisible
                        ? const Icon(Icons.keyboard_rounded)
                        : ColorFiltered(
                            colorFilter: _greyscale,
                            child: Image(
                              width: 24,
                              height: 24,
                              image: ResilientNetworkImage(Uri.parse(_emotes[_emoteIndex])),
                            ),
                          ),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: Theme.of(context).colorScheme.primary,
                    splashRadius: 24,
                    onPressed: () => sendMessage(_textEditingController?.text ?? ''),
                  ),
                  border: InputBorder.none,
                  hintMaxLines: 1,
                  hintText: () {
                    final l10n = AppLocalizations.of(context)!;
                    if (_textSeed < 0.5) {
                      return l10n.sendAMessage;
                    } else if (_textSeed < 0.9) {
                      return l10n.writeSomething;
                    } else if (_textSeed < 0.99) {
                      return l10n.speakToTheCrowds;
                    } else if (_textSeed < 0.999) {
                      return l10n.shareYourThoughts;
                    }
                    return l10n.saySomethingYouLittleBitch;
                  }(),
                ),
                onChanged: (text) {
                  final filtered = text.replaceAll('\n', ' ');
                  if (filtered == text) {
                    return;
                  }
                  setState(() {
                    _textEditingController?.value = TextEditingValue(
                      text: filtered,
                      selection: TextSelection.fromPosition(
                        TextPosition(offset: _textEditingController?.text.length ?? 0),
                      ),
                    );
                  });
                },
                onSubmitted: sendMessage,
                onTap: () {
                  setState(() => _isEmotePickerVisible = false);
                  _chatInputFocusNode.requestFocus();
                },
              ),
            ),
          ),
          _isEmotePickerVisible
              ? EmotePickerWidget(
                  channel: widget.channel,
                  emotes: widget.emotes,
                  onEmoteSelected: (emote) {
                    if (emote == null) {
                      setState(() {
                        _isEmotePickerVisible = false;
                      });
                      return;
                    }
                    if (_textEditingController?.text.isNotEmpty ?? false) {
                      _textEditingController?.text = "${_textEditingController?.text} ${emote.code} ";
                    } else {
                      _textEditingController?.text = "${emote.code} ";
                    }
                  })
              : Container(),
        ],
      ),
    );
  }
}
