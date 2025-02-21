import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as customtabs;
import 'package:url_launcher/url_launcher.dart';

Future<void> openUrl(Uri url) async {
  if (!url.hasScheme) {
    await customtabs.launchUrl(url.replace(scheme: 'http'),
      customTabsOptions: customtabs.CustomTabsOptions(
        shareState: customtabs.CustomTabsShareState.on,
        urlBarHidingEnabled: true,
        showTitle: true,
        closeButton: customtabs.CustomTabsCloseButton(
          icon: customtabs.CustomTabsCloseButtonIcons.back,
        ),
      ),
      safariVCOptions: customtabs.SafariViewControllerOptions(
        barCollapsingEnabled: true,
        dismissButtonStyle: customtabs.SafariViewControllerDismissButtonStyle.close,
      ),
    );
  } else if (url.isScheme("http") || url.isScheme("https")) {
    await customtabs.launchUrl(url,
      customTabsOptions: customtabs.CustomTabsOptions(
        shareState: customtabs.CustomTabsShareState.on,
        urlBarHidingEnabled: true,
        showTitle: true,
        closeButton: customtabs.CustomTabsCloseButton(
          icon: customtabs.CustomTabsCloseButtonIcons.back,
        ),
      ),
      safariVCOptions: customtabs.SafariViewControllerOptions(
        barCollapsingEnabled: true,
        dismissButtonStyle: customtabs.SafariViewControllerDismissButtonStyle.close,
      ),
    );
  } else {
    await launchUrl(url);
  }
}
