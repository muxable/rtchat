import 'dart:convert';
import 'dart:io';

class PlayStoreSearch {
  Future<String?> lookupVersion(String packageName) async {
    final client =
        HttpClient()..connectionTimeout = const Duration(seconds: 10);

    try {
      final uri = Uri.https('play.google.com', '/store/apps/details', {
        'id': packageName,
        'hl': 'en',
        'gl': 'US',
        '_cb': DateTime.now().microsecondsSinceEpoch.toString(),
      });

      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
      );

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final html = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 10));

      return _extractVersion(html);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  String? _extractVersion(String html) {
    // Try the older Play Store page structure first.
    final labelIndex = html.toLowerCase().indexOf('current version');

    if (labelIndex != -1) {
      final endIndex = (labelIndex + 1500).clamp(0, html.length);
      final section = html.substring(labelIndex, endIndex);

      final match = RegExp(
        r'class="htlgb"[^>]*>\s*([^<]+)',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(section);

      final version = _validVersion(match?.group(1));
      if (version != null) return version;
    }

    // Fallback for the redesigned Play Store page.
    // These numeric keys are undocumented and may change.
    final numericKeyPattern = RegExp(
      r'"(?:140|141|142|143|144|145)":\[\[\["([^"]+)"',
    );

    for (final match in numericKeyPattern.allMatches(html)) {
      final version = _validVersion(match.group(1));
      if (version != null) return version;
    }

    return null;
  }

  String? _validVersion(String? value) {
    if (value == null) return null;

    final candidate = value.trim();
    if (!RegExp(r'^\d+(?:\.\d+){1,3}$').hasMatch(candidate)) {
      return null;
    }

    return candidate;
  }
}
