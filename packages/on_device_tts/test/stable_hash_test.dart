import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

void main() {
  test('matches the published FNV-1a 32-bit test vectors', () {
    // From the FNV reference test suite (draft-eastlake-fnv).
    expect(fnv1a32(''), 0x811c9dc5);
    expect(fnv1a32('a'), 0xe40c292c);
    expect(fnv1a32('b'), 0xe70c2de5);
    expect(fnv1a32('foobar'), 0xbf9cf968);
  });

  test('hashes the UTF-8 bytes', () {
    // 'é' is two bytes, 0xc3 0xa9.
    expect(fnv1a32('é'), _reference([0xc3, 0xa9]));
    expect(fnv1a32('日本'), _reference([0xe6, 0x97, 0xa5, 0xe6, 0x9c, 0xac]));
  });

  test('is unsigned 32-bit', () {
    for (final text in ['twitch:1', 'kick:123456', 'x' * 1000]) {
      final hash = fnv1a32(text);
      expect(hash, inInclusiveRange(0, 0xffffffff));
      expect(hash, _reference(text.codeUnits));
    }
  });

  test('keys chatters to the same voices on every run', () {
    // Pinned so a change to the hash, which would give every chatter a new
    // voice, doesn't go unnoticed.
    expect(fnv1a32('twitch:1'), 0x3cef4db3);
    expect(fnv1a32('twitch:42'), 0x03bea9fa);
    expect(fnv1a32('kick:login:muxfd'), 0x0241e6da);
  });
}

/// FNV-1a 32 by the book, with BigInt so nothing can overflow.
int _reference(List<int> bytes) {
  var hash = BigInt.from(0x811c9dc5);
  final prime = BigInt.from(0x01000193);
  final mask = BigInt.from(0xffffffff);
  for (final byte in bytes) {
    hash = ((hash ^ BigInt.from(byte)) * prime) & mask;
  }
  return hash.toInt();
}
