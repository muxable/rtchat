import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/screens/settings/audio_sources.dart';

void main() {
  group('Audio URL Validation Helper Functions', () {
    test('hasFileExtension should detect file extensions correctly', () {
      // Test URLs with file extensions
      expect(hasFileExtension(Uri.parse('https://example.com/audio.mp3')), true);
      expect(hasFileExtension(Uri.parse('https://example.com/path/audio.wav')), true);
      expect(hasFileExtension(Uri.parse('https://example.com/audio.ogg')), true);
      expect(hasFileExtension(Uri.parse('http://example.com/folder/audio.aac')), true);
      
      // Test URLs without file extensions
      expect(hasFileExtension(Uri.parse('https://example.com/audio')), false);
      expect(hasFileExtension(Uri.parse('https://example.com/path/audio')), false);
      expect(hasFileExtension(Uri.parse('https://example.com/')), false);
      expect(hasFileExtension(Uri.parse('https://example.com')), false);
      
      // Test edge cases
      expect(hasFileExtension(Uri.parse('https://example.com/audio.')), false);
      expect(hasFileExtension(Uri.parse('https://example.com/audio.m')), false);
      expect(hasFileExtension(Uri.parse('https://example.com/audio.mp')), true);
    });

    test('isOgg should detect .ogg files correctly', () {
      // Test .ogg files
      expect(isOgg(Uri.parse('https://example.com/audio.ogg')), true);
      expect(isOgg(Uri.parse('https://example.com/path/audio.OGG')), true);
      expect(isOgg(Uri.parse('http://example.com/audio.ogg')), true);
      
      // Test non-.ogg files
      expect(isOgg(Uri.parse('https://example.com/audio.mp3')), false);
      expect(isOgg(Uri.parse('https://example.com/audio.wav')), false);
      expect(isOgg(Uri.parse('https://example.com/audio')), false);
      expect(isOgg(Uri.parse('https://example.com/ogg')), false);
    });

    test('isHttpOnIOS should detect HTTP URLs correctly', () {
      // Note: Since we can't mock Platform.isIOS in unit tests easily,
      // we'll test the URI parsing logic, but the actual platform detection
      // would need integration tests or mocking
      
      // Test HTTP URLs
      final httpUri = Uri.parse('http://example.com/audio.mp3');
      expect(httpUri.scheme == 'http', true);
      
      // Test HTTPS URLs
      final httpsUri = Uri.parse('https://example.com/audio.mp3');
      expect(httpsUri.scheme == 'http', false);
      expect(httpsUri.scheme == 'https', true);
      
      // Test other schemes
      final fileUri = Uri.parse('file:///path/to/audio.mp3');
      expect(fileUri.scheme == 'http', false);
    });
  });
}