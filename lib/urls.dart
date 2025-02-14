import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as customtabs;
import 'package:url_launcher/url_launcher.dart';

Future<void> openUrl(Uri url) async {
  if (!url.hasScheme) {
    await customtabs.launchUrl(url.replace(scheme: 'http'));
  } else if (url.isScheme("http") || url.isScheme("https")) {
    await customtabs.launchUrl(url);
  } else {
    await launchUrl(url);
  }
}
