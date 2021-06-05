import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/layout.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AddTabScreen extends StatefulWidget {
  AddTabScreen({Key? key}) : super(key: key);

  @override
  _AddTabScreenState createState() => _AddTabScreenState();
}

class _AddTabScreenState extends State<AddTabScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  InAppWebViewController? _webViewController;
  final GlobalKey _webViewKey = GlobalKey();
  final InAppWebViewGroupOptions _webViewOptions = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(transparentBackground: true),
      android: AndroidInAppWebViewOptions(useHybridComposition: true),
      ios: IOSInAppWebViewOptions(allowsInlineMediaPlayback: true));

  @override
  void dispose() {
    _labelController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add a Browser Source"), actions: [
        IconButton(
            icon: Icon(Icons.check),
            tooltip: "Add",
            onPressed: () {
              Provider.of<LayoutModel>(context, listen: false).addTab(PanelTab(
                label: _labelController.text,
                uri: _urlController.text,
              ));
              Navigator.maybePop(context);
            })
      ]),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                  hintText: 'Label',
                ),
              ),
              TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    hintText: 'URL',
                  ),
                  onChanged: (value) {
                    final url = Uri.tryParse(value);
                    if (url == null) {
                      _webViewController?.loadUrl(
                          urlRequest:
                              URLRequest(url: Uri.parse("about:blank")));
                      return;
                    }
                    _webViewController?.loadUrl(
                        urlRequest: URLRequest(url: url));
                  }),
              Padding(padding: EdgeInsets.all(8), child: Text("Preview")),
              Expanded(
                child: InAppWebView(
                  key: _webViewKey,
                  initialOptions: _webViewOptions,
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
