import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import 'voice_pack_catalog.dart';
import 'voice_pack_exceptions.dart';

/// Extracts the archive at [archivePath] into [destination], dropping the
/// first [stripComponents] components of each entry's path.
///
/// Archives are untrusted: an entry with an absolute path or `..` that
/// leaves [destination], a symbolic link that points outside it, a hard
/// link or a device file makes the whole archive fail with a
/// [VoicePackArchiveException]. Symbolic links are created after every
/// regular file, so no file is ever written through one.
///
/// Compressed tar archives are first decompressed to [scratchPath].
///
/// This is synchronous and slow for large archives; run it in an isolate.
void extractArchive({
  required String archivePath,
  required VoicePackArchiveType type,
  required String destination,
  required String scratchPath,
  int stripComponents = 0,
}) {
  Directory(destination).createSync(recursive: true);
  final InputStream input;
  switch (type) {
    case VoicePackArchiveType.tarBz2 || VoicePackArchiveType.tarGz:
      _decompress(archivePath, scratchPath, type);
      input = InputFileStream(scratchPath);
    case VoicePackArchiveType.tar || VoicePackArchiveType.zip:
      input = InputFileStream(archivePath);
    case VoicePackArchiveType.unknown:
      throw const VoicePackArchiveException('unknown archive type');
  }
  try {
    final Archive archive;
    try {
      if (type == VoicePackArchiveType.zip) {
        archive = ZipDecoder().decodeStream(input);
      } else {
        final decoder = TarDecoder();
        archive = decoder.decodeStream(input, verify: true);
        for (final entry in decoder.files) {
          if (_forbiddenTarTypes.contains(entry.typeFlag)) {
            throw VoicePackArchiveException(
                'unsupported entry type ${entry.typeFlag}: ${entry.filename}');
          }
        }
      }
    } on ArchiveException catch (e) {
      throw VoicePackArchiveException('damaged archive: ${e.message}');
    }
    _extractEntries(archive, destination, stripComponents);
  } finally {
    input.closeSync();
    final scratch = File(scratchPath);
    if (scratch.existsSync()) scratch.deleteSync();
  }
}

const _forbiddenTarTypes = {
  TarFile.hardLink,
  TarFile.charSpec,
  TarFile.blockSpec,
  TarFile.fifo,
};

void _decompress(String from, String to, VoicePackArchiveType type) {
  final input = InputFileStream(from);
  final output = OutputFileStream(to);
  bool ok;
  try {
    ok = type == VoicePackArchiveType.tarBz2
        ? BZip2Decoder().decodeStream(input, output, verify: true)
        : GZipDecoder().decodeStream(input, output, verify: true);
  } on ArchiveException catch (e) {
    throw VoicePackArchiveException('damaged archive: ${e.message}');
  } finally {
    input.closeSync();
    output.closeSync();
  }
  if (!ok) throw const VoicePackArchiveException('damaged archive');
}

void _extractEntries(Archive archive, String destination, int stripComponents) {
  final root = p.normalize(p.absolute(destination));
  final links = <(String, String)>[];
  for (final entry in archive) {
    final name = entry.name;
    if (!isSafeRelativePath(name)) {
      throw VoicePackArchiveException('unsafe path in archive: $name');
    }
    final parts =
        p.posix.split(p.posix.normalize(name)).where((s) => s != '.').toList();
    if (parts.length <= stripComponents) continue;
    final target = p.joinAll([root, ...parts.skip(stripComponents)]);
    if (!p.isWithin(root, target)) {
      throw VoicePackArchiveException('unsafe path in archive: $name');
    }
    if (entry.isSymbolicLink) {
      final link = entry.symbolicLink!;
      final resolved = p.normalize(p.join(p.dirname(target), link));
      if (p.posix.isAbsolute(link) ||
          link.contains('\\') ||
          !(p.isWithin(root, resolved) || p.equals(root, resolved))) {
        throw VoicePackArchiveException(
            'link points outside the pack: $name -> $link');
      }
      links.add((target, link));
    } else if (entry.isDirectory) {
      Directory(target).createSync(recursive: true);
    } else {
      Directory(p.dirname(target)).createSync(recursive: true);
      final output = OutputFileStream(target);
      try {
        entry.writeContent(output);
      } finally {
        output.closeSync();
      }
    }
  }
  final realRoot = Directory(root).resolveSymbolicLinksSync();
  for (final (path, target) in links) {
    Link(path).createSync(target, recursive: true);
  }
  // Catch links that only escape through other links.
  for (final (path, _) in links) {
    final String resolved;
    try {
      resolved = Link(path).resolveSymbolicLinksSync();
    } on FileSystemException {
      continue; // Dangling, and lexically inside the pack.
    }
    if (!p.isWithin(realRoot, resolved) && !p.equals(realRoot, resolved)) {
      throw VoicePackArchiveException('link points outside the pack: $path');
    }
  }
}
