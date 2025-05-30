import 'package:flutter/material.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/scanner_error.dart';
import 'package:rtchat/components/scanner_settings.dart';
import 'package:rtchat/models/quick_links.dart';
import 'package:rtchat/screens/settings/dismissible_delete_background.dart';

import './l10n/app_localizations.dart';

class QuickLinksScreen extends StatefulWidget {
  const QuickLinksScreen({super.key});

  @override
  State<QuickLinksScreen> createState() => _QuickLinksScreenState();
}

const quickLinksIconsMap = {
  "home": Icons.home_outlined,
  "manage_accounts": Icons.manage_accounts_outlined,
  "account_balance": Icons.account_balance_outlined,
  "view_list": Icons.view_list_outlined,
  "code": Icons.code_outlined,
  "analytics": Icons.analytics_outlined,
  "store": Icons.store_outlined,
  "receipt": Icons.receipt_outlined,
  "gavel": Icons.gavel_outlined,
  "rule": Icons.rule_outlined,
  "sensors": Icons.sensors_outlined,
  "speaker_notes": Icons.speaker_notes_outlined,
  "settings_input_antenna": Icons.settings_input_antenna_outlined,
  "settings_input_component": Icons.settings_input_component_outlined,
  "donut_small": Icons.donut_small_outlined,
  "online_prediction": Icons.online_prediction_outlined,
  "link": Icons.link_outlined,
};

class _QuickLinksScreenState extends State<QuickLinksScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textEditingController = TextEditingController();
  final _labelEditingController = TextEditingController();
  String _activeIcon = "view_list";
  String _url = "";
  MobileScannerController _scanController = MobileScannerController(
    // facing: CameraFacing.back,
    // torchEnabled: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void initState() {
    super.initState();

    _textEditingController.addListener(() {
      setState(() => _url = _textEditingController.text);
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _labelEditingController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.quickLinks)),
      body: SafeArea(
        child: Column(children: [
          Expanded(child:
              Consumer<QuickLinksModel>(builder: (context, quickLinks, child) {
            return ReorderableListView(
              onReorder: quickLinks.swapSource,
              children: quickLinks.sources.map((source) {
                return Dismissible(
                  key: ValueKey(source),
                  background: const DismissibleDeleteBackground(),
                  child: Tooltip(
                      triggerMode: TooltipTriggerMode.tap,
                      message:
                          AppLocalizations.of(context)!.swipeToDeleteQuickLinks,
                      child: ListTile(
                        key: ValueKey(source),
                        leading:
                            Icon(quickLinksIconsMap[source.icon] ?? Icons.link),
                        title: Text(source.label),
                        subtitle: Text(source.url.toString()),
                        trailing: const Icon(Icons.drag_handle),
                      )),
                  onDismissed: (direction) {
                    quickLinks.removeSource(source);
                  },
                );
              }).toList(),
            );
          })),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Form(
                key: _formKey,
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    PopupMenuButton<String>(
                      icon: Icon(quickLinksIconsMap[_activeIcon] ?? Icons.link),
                      onSelected: (result) {
                        setState(() {
                          _activeIcon = result;
                        });
                      },
                      itemBuilder: (context) {
                        final entries = quickLinksIconsMap.entries.toList()
                          ..sort((a, b) => a.key.compareTo(b.key));
                        return entries
                            .map((entry) => PopupMenuItem(
                                value: entry.key, child: Icon(entry.value)))
                            .toList();
                      },
                    ),
                    Expanded(
                      child: Column(children: [
                        _url.isNotEmpty
                            ? FutureBuilder<String>(
                                future: retrieveName(_url),
                                builder: (context, snapshot) {
                                  return TextFormField(
                                    controller: _labelEditingController,
                                    decoration: InputDecoration(
                                      hintText: snapshot.data ??
                                          AppLocalizations.of(context)!
                                              .quickLinksLabelHint,
                                    ),
                                  );
                                },
                              )
                            : Container(),
                        TextFormField(
                            controller: _textEditingController,
                            decoration: InputDecoration(
                                hintText: "URL",
                                suffixIcon: IconButton(
                                    icon: const Icon(Icons.qr_code_scanner),
                                    onPressed: () {
                                      final messenger =
                                          ScaffoldMessenger.of(context);

                                      showModalBottomSheet(
                                        isScrollControlled: true,
                                        context: context,
                                        builder: (ctx) {
                                          return Stack(
                                            children: [
                                              MobileScanner(
                                                errorBuilder:
                                                    (context, error, child) {
                                                  return ScannerErrorWidget(
                                                      error: error);
                                                },
                                                controller: _scanController,
                                                onDetect: (capture) {
                                                  final List<Barcode> barcodes =
                                                      capture.barcodes;

                                                  if (barcodes.isEmpty) {
                                                    messenger.showSnackBar(SnackBar(
                                                        content: Text(
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .invalidUrlErrorText)));
                                                  }

                                                  final barcode =
                                                      barcodes.first;

                                                  if (barcode.rawValue ==
                                                          null ||
                                                      barcode
                                                          .rawValue!.isEmpty) {
                                                    messenger.showSnackBar(SnackBar(
                                                        content: Text(
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .invalidUrlErrorText)));

                                                    Navigator.pop(ctx);
                                                  }

                                                  _textEditingController.text =
                                                      '${barcode.rawValue}';

                                                  Navigator.pop(ctx);
                                                },
                                              ),
                                              Positioned(
                                                top: 50,
                                                left: 0,
                                                right: 0,
                                                child: ScannerSettings(
                                                    scanController:
                                                        _scanController),
                                              ),
                                            ],
                                          );
                                        },
                                      ).then((value) {
                                        _scanController.dispose();

                                        //re initialize controller
                                        _scanController =
                                            MobileScannerController(
                                          detectionSpeed:
                                              DetectionSpeed.noDuplicates,
                                        );
                                      });
                                    })),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  Uri.tryParse(value) == null) {
                                return AppLocalizations.of(context)!
                                    .invalidUrlErrorText;
                              }
                              final quickLinksModel =
                                  Provider.of<QuickLinksModel>(context,
                                      listen: false);
                              if (quickLinksModel.sources.any((s) =>
                                  s.url.toString() == Uri.encodeFull(value))) {
                                return AppLocalizations.of(context)!
                                    .duplicateUrlErrorText;
                              }
                              return null;
                            },
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                            onEditingComplete: addLink),
                      ]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: addLink,
                    )
                  ]),
                ])),
          ),
        ]),
      ),
    );
  }

  Future<String> retrieveName(String url) async {
    try {
      final metadata = await MetadataFetch.extract(url);
      return metadata?.title ?? url;
    } catch (e) {
      return url;
    }
  }

  void addLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final model = Provider.of<QuickLinksModel>(context, listen: false);
    final focus = FocusScope.of(context);
    final label = _labelEditingController.text.isEmpty
        ? await retrieveName(_url)
        : _labelEditingController.text;
    model.addSource(QuickLinkSource(
        _activeIcon, Uri.parse(_textEditingController.text), label));
    _textEditingController.clear();
    _labelEditingController.clear();
    focus.unfocus();
  }
}
