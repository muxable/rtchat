import 'dart:convert';

/// The 32-bit FNV-1a hash of [text]'s UTF-8 bytes, as an unsigned integer.
///
/// Unlike [String.hashCode], it is the same on every run, platform and Dart
/// version, so it can pick something that has to stay put, such as a
/// chatter's voice.
int fnv1a32(String text) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(text)) {
    hash ^= byte;
    // hash * 16777619 (0x01000193) mod 2^32, without products past 2^53 so
    // it's exact when compiled to JavaScript too.
    hash = (hash * 0x193 + ((hash & 0xff) << 24)) & 0xffffffff;
  }
  return hash;
}
