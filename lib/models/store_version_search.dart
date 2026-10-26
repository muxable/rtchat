import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:rtchat/models/app_store_search.dart';
import 'package:rtchat/models/play_store_search.dart';

class StoreVersionResult {
  const StoreVersionResult({
    required this.currentVersion,
    required this.storeVersion,
    required this.storeUrl,
  });

  final String currentVersion;
  final String storeVersion;
  final Uri storeUrl;

  bool get updateAvailable =>
      StoreVersionSearch.compareVersions(storeVersion, currentVersion) > 0;
}

// searching in play won't be needed once native app updating is implemented
class StoreVersionSearch {
  StoreVersionSearch({PlayStoreSearch? playStore, AppStoreSearch? appStore})
    : _playStore = playStore ?? PlayStoreSearch(),
      _appStore = appStore ?? AppStoreSearch();

  final PlayStoreSearch _playStore;
  final AppStoreSearch _appStore;

  Future<StoreVersionResult?> checkForUpdate() async {
    if (!Platform.isAndroid && !Platform.isIOS) return null;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (Platform.isAndroid) {
        final version = await _playStore.lookupVersion(packageInfo.packageName);

        if (version == null) return null;

        return StoreVersionResult(
          currentVersion: currentVersion,
          storeVersion: version,
          storeUrl: Uri.https('play.google.com', '/store/apps/details', {
            'id': packageInfo.packageName,
          }),
        );
      }

      final result = await _appStore.lookup(packageInfo.packageName);
      if (result == null) return null;

      return StoreVersionResult(
        currentVersion: currentVersion,
        storeVersion: result.version,
        storeUrl: result.storeUrl,
      );
    } catch (_) {
      return null;
    }
  }

  static int compareVersions(String a, String b) {
    List<int> parts(String version) {
      // Ignore build metadata, such as 1.2.3+15.
      final normalized = version.split('+').first.trim();

      if (!RegExp(r'^\d+(?:\.\d+)*$').hasMatch(normalized)) {
        throw FormatException('Invalid version: $version');
      }

      return normalized.split('.').map(int.parse).toList();
    }

    final left = parts(a);
    final right = parts(b);
    final length = left.length > right.length ? left.length : right.length;

    for (var i = 0; i < length; i++) {
      final x = i < left.length ? left[i] : 0;
      final y = i < right.length ? right[i] : 0;

      if (x != y) return x.compareTo(y);
    }

    return 0;
  }
}
