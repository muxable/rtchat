import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/drawer/sliver_search_bar.dart';
import 'package:rtchat/components/drawer/sliver_title.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/adapters/chat_state.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/user.dart';

class EndDrawerWidget extends StatefulWidget {
  final Channel channel;
  final VoidCallback onClose;

  const EndDrawerWidget({
    required this.channel,
    required this.onClose,
    super.key,
  });

  @override
  State<EndDrawerWidget> createState() => EndDrawerWidgetState();
}

class EndDrawerWidgetState extends State<EndDrawerWidget> {
  String _search = '';
  Viewers? _viewers;
  bool _isLoading = true;
  bool _isError = false;

  // Incremented for each request so older requests cannot update the UI.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadViewers();
  }

  @override
  void didUpdateWidget(covariant EndDrawerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.channel != widget.channel) {
      _search = '';
      _viewers = null;
      _isLoading = true;
      _isError = false;
      _loadViewers();
    }
  }

  Future<void> _loadViewers() async {
    final requestId = ++_requestId;
    try {
      // Twitch lists chatters with the caller's token when the channel's own
      // isn't stored, so call as the account on its provider.
      final api = Provider.of<UserModel>(
        context,
        listen: false,
      ).apiOn(widget.channel.provider);

      final viewers = await ChatStateAdapter(
        api,
      ).getViewers(channelId: widget.channel.toString());
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _viewers = viewers;
        _isLoading = false;
        _isError = false;
      });
    } catch (error, stackTrace) {
      // Ignore failures from requests belonging to an older channel.
      if (!mounted || requestId != _requestId) return;
      debugPrint('Failed to load viewers: $error');
      debugPrintStack(stackTrace: stackTrace);

      setState(() {
        _isLoading = false;
        _isError = true;
      });
      _showTemporaryError();
      widget.onClose();
    }
  }

  void _showTemporaryError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.errorFetchingViewerList),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_isError || _viewers == null) {
      return const SizedBox.shrink();
    }

    final filtered = _viewers!.query(_search);
    final localizations = AppLocalizations.of(context)!;

    return Container(
      color: Theme.of(context).canvasColor,
      child: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(top: 24),
              sliver: SliverAppBar(
                actions: const [SizedBox()],
                centerTitle: false,
                title: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    localizations.searchViewers,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
              ),
            ),
            SliverSearchBarWidget(
              onFilterBySearchBarText: (value) {
                setState(() => _search = value);
              },
            ),
            if (filtered.broadcaster.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.only(top: 8, left: 8),
                sliver: SliverTitleWidget(title: localizations.broadcaster),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(filtered.broadcaster[index]),
                  ),
                  childCount: filtered.broadcaster.length,
                ),
              ),
            ],
            if (filtered.moderators.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.only(top: 8, left: 8),
                sliver: SliverTitleWidget(title: localizations.moderators),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(filtered.moderators[index]),
                  ),
                  childCount: filtered.moderators.length,
                ),
              ),
            ],
            if (filtered.vips.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.only(top: 8, left: 8),
                sliver: SliverTitleWidget(title: localizations.communityVips),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(filtered.vips[index]),
                  ),
                  childCount: filtered.vips.length,
                ),
              ),
            ],
            if (filtered.viewers.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.only(top: 8, left: 8),
                sliver: SliverTitleWidget(title: localizations.viewers),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(filtered.viewers[index]),
                  ),
                  childCount: filtered.viewers.length,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
