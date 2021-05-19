import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/layout.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AddTabScreen extends StatefulWidget {
  AddTabScreen({Key? key}) : super(key: key);

  @override
  _AddTabScreenState createState() => _AddTabScreenState();
}

class _AddTabScreenState extends State<AddTabScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  WebViewController? _webViewController;

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
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
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
                    _webViewController?.loadUrl(value);
                  }),
              Padding(padding: EdgeInsets.all(8), child: Text("Preview")),
              Expanded(
                  child: WebView(
                javascriptMode: JavascriptMode.unrestricted,
                allowsInlineMediaPlayback: true,
                initialMediaPlaybackPolicy:
                    AutoMediaPlaybackPolicy.always_allow,
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
              )),
            ],
          ),
        ),
      ),
    );
  }
}
