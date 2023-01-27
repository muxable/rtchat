import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as customtabs;
import 'package:url_launcher/url_launcher.dart';

Future<void> openUrl(Uri url) async {
  if (!url.hasScheme) {
    await customtabs.launch(url.replace(scheme: 'http').toString());
  } else if (url.isScheme("http") || url.isScheme("https")) {
    await customtabs.launch(url.toString());
  } else {
    await launchUrl(url);
  }
}
