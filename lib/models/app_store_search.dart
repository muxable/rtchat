import 'dart:convert';
import 'dart:io';

class AppStoreInfo {
  const AppStoreInfo({required this.version, required this.storeUrl});

  final String version;
  final Uri storeUrl;
}

class AppStoreSearch {
  Future<AppStoreInfo?> lookup(String bundleId) async {
    final client =
        HttpClient()..connectionTimeout = const Duration(seconds: 10);

    try {
      final uri = Uri.https('itunes.apple.com', '/lookup', {
        'bundleId': bundleId,
        'country': 'us',
      });

      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != HttpStatus.ok) return null;

      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 10));

      final json = jsonDecode(body) as Map<String, dynamic>;
      final results = json['results'] as List<dynamic>?;

      if (results == null || results.isEmpty) return null;

      final app = results.first as Map<String, dynamic>;
      final version = app['version'] as String?;
      final url = app['trackViewUrl'] as String?;

      if (version == null || url == null) return null;

      return AppStoreInfo(version: version, storeUrl: Uri.parse(url));
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
