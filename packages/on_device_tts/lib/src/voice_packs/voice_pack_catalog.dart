import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Thrown when a catalog can't be read at all, e.g. it isn't JSON or its
/// schema is newer than this package understands.
///
/// A single bad pack doesn't throw: it is left out of the catalog so the
/// other packs stay usable.
class VoicePackCatalogException implements Exception {
  final String message;

  const VoicePackCatalogException(this.message);

  @override
  String toString() => 'VoicePackCatalogException: $message';
}

/// The kind of model in a voice pack, which tells the engine how to load it.
enum VoicePackModelType {
  kokoro,
  kitten,
  vits,
  matcha,

  /// A model type this version of the package doesn't know. Packs with it
  /// are kept in the catalog but aren't [VoicePack.isSupported].
  unknown;

  static VoicePackModelType parse(String value) {
    for (final type in values) {
      if (type != unknown && type.name == value) return type;
    }
    return unknown;
  }
}

/// The archive format of a [VoicePackFile] that gets extracted on install.
enum VoicePackArchiveType {
  tarBz2('tar.bz2'),
  tarGz('tar.gz'),
  tar('tar'),
  zip('zip'),

  /// An archive format this version of the package can't extract. Packs
  /// with it aren't [VoicePack.isSupported].
  unknown('');

  final String id;

  const VoicePackArchiveType(this.id);

  static VoicePackArchiveType parse(String value) {
    for (final type in values) {
      if (type != unknown && type.id == value) return type;
    }
    return unknown;
  }
}

/// One speaker of a voice pack. Multi-speaker models pick the speaker by
/// [index] (sherpa-onnx's speaker id, `sid`).
@immutable
class VoicePackSpeaker {
  /// The speaker's index in the model.
  final int index;

  /// The name to show, e.g. `af_heart` or `Bella`.
  final String name;

  /// `female`, `male` or null when unknown.
  final String? gender;

  /// The BCP-47 tag of the language the speaker speaks, when the pack speaks
  /// several and this speaker only one of them.
  final String? language;

  const VoicePackSpeaker({
    required this.index,
    required this.name,
    this.gender,
    this.language,
  });

  factory VoicePackSpeaker.fromJson(Map<String, Object?> json) {
    return VoicePackSpeaker(
      index: _int(json, 'id'),
      name: _string(json, 'name'),
      gender: _optionalString(json, 'gender'),
      language: _optionalString(json, 'language'),
    );
  }

  Map<String, Object?> toJson() => {
        'id': index,
        'name': name,
        if (gender != null) 'gender': gender,
        if (language != null) 'language': language,
      };

  @override
  bool operator ==(Object other) =>
      other is VoicePackSpeaker &&
      other.index == index &&
      other.name == name &&
      other.gender == gender &&
      other.language == language;

  @override
  int get hashCode => Object.hash(index, name, gender, language);
}

/// A file to download for a voice pack.
@immutable
class VoicePackFile {
  /// Where to download the file from.
  final Uri url;

  /// The size of the download in bytes.
  final int size;

  /// The lowercase hex SHA-256 of the download.
  final String sha256;

  /// Where the file goes, relative to the pack's directory. For an archive
  /// this is the directory it's extracted into; empty means the pack's
  /// directory itself.
  final String path;

  /// The archive format to extract, or null to keep the file as it is.
  final VoicePackArchiveType? archive;

  /// How many leading path components to drop from each archive entry, like
  /// `tar --strip-components`.
  final int stripComponents;

  const VoicePackFile({
    required this.url,
    required this.size,
    required this.sha256,
    required this.path,
    this.archive,
    this.stripComponents = 0,
  });

  factory VoicePackFile.fromJson(Map<String, Object?> json) {
    final url = Uri.tryParse(_string(json, 'url'));
    if (url == null || !(url.isScheme('https') || url.isScheme('http'))) {
      throw const FormatException('url must be an http(s) URL');
    }
    final size = _int(json, 'size');
    if (size < 0) throw const FormatException('size must not be negative');
    final sha256 = _string(json, 'sha256').toLowerCase();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256)) {
      throw const FormatException('sha256 must be 64 hex digits');
    }
    final path = _optionalString(json, 'path') ?? '';
    if (!isSafeRelativePath(path)) {
      throw FormatException('path must stay inside the pack: $path');
    }
    final archive = _optionalString(json, 'archive');
    final strip = json['strip_components'] ?? 0;
    if (strip is! int || strip < 0) {
      throw const FormatException('strip_components must be a natural number');
    }
    if (archive == null && path.isEmpty) {
      throw const FormatException('a file that is not an archive needs a path');
    }
    return VoicePackFile(
      url: url,
      size: size,
      sha256: sha256,
      path: path,
      archive: archive == null ? null : VoicePackArchiveType.parse(archive),
      stripComponents: strip,
    );
  }

  Map<String, Object?> toJson() => {
        'url': url.toString(),
        'size': size,
        'sha256': sha256,
        'path': path,
        if (archive != null) 'archive': archive!.id,
        if (stripComponents != 0) 'strip_components': stripComponents,
      };

  @override
  bool operator ==(Object other) =>
      other is VoicePackFile &&
      other.url == url &&
      other.size == size &&
      other.sha256 == sha256 &&
      other.path == path &&
      other.archive == archive &&
      other.stripComponents == stripComponents;

  @override
  int get hashCode =>
      Object.hash(url, size, sha256, path, archive, stripComponents);
}

/// The license of a voice pack and who to credit.
@immutable
class VoicePackLicense {
  /// An SPDX identifier where there is one, e.g. `Apache-2.0` or `CC0-1.0`.
  final String name;

  /// Where to read the license.
  final Uri? url;

  /// Credit to show with the voice.
  final String? attribution;

  const VoicePackLicense({required this.name, this.url, this.attribution});

  factory VoicePackLicense.fromJson(Map<String, Object?> json) {
    final url = _optionalString(json, 'url');
    return VoicePackLicense(
      name: _string(json, 'name'),
      url: url == null ? null : Uri.tryParse(url),
      attribution: _optionalString(json, 'attribution'),
    );
  }

  Map<String, Object?> toJson() => {
        'name': name,
        if (url != null) 'url': url.toString(),
        if (attribution != null) 'attribution': attribution,
      };
}

/// A downloadable voice pack: one model with its speakers.
@immutable
class VoicePack {
  /// Identifies the pack, and names its directory. Lowercase letters,
  /// digits, `.`, `_` and `-`.
  final String id;

  /// The name to show, e.g. `Kokoro (multilingual)`.
  final String name;

  /// The pack's revision. Bump it to offer an upgrade to people who have the
  /// pack installed; a change in any file's checksum does too.
  final int version;

  /// The model type exactly as the catalog spells it.
  final String modelTypeName;

  /// BCP-47 tags of the languages the pack speaks, e.g. `en-US`, `pt-BR`.
  final List<String> languages;

  final List<VoicePackSpeaker> speakers;

  final List<VoicePackFile> files;

  final VoicePackLicense? license;

  /// The oldest app version that can use the pack, e.g. `1.2.0`.
  final String? minAppVersion;

  /// How the engine loads the pack: paths relative to the pack directory and
  /// model options, keyed by name. The engine defines the keys.
  final Map<String, Object?> config;

  const VoicePack({
    required this.id,
    required this.name,
    this.version = 1,
    required this.modelTypeName,
    required this.languages,
    this.speakers = const [],
    required this.files,
    this.license,
    this.minAppVersion,
    this.config = const {},
  });

  VoicePackModelType get modelType => VoicePackModelType.parse(modelTypeName);

  /// Whether this version of the package can install and load the pack.
  bool get isSupported =>
      modelType != VoicePackModelType.unknown &&
      files.every((file) => file.archive != VoicePackArchiveType.unknown);

  /// The total download size in bytes.
  int get downloadSize => files.fold(0, (sum, file) => sum + file.size);

  /// Whether the pack speaks [language], a BCP-47 tag such as `en` or
  /// `pt-BR`. A bare language matches every region.
  bool speaks(String language) {
    final wanted = _normalizeTag(language);
    return languages
        .map(_normalizeTag)
        .any((have) => have == wanted || have.startsWith('$wanted-'));
  }

  /// Whether an app at [appVersion] can use the pack.
  bool isCompatibleWith(String appVersion) {
    final min = minAppVersion;
    return min == null || compareVersions(appVersion, min) >= 0;
  }

  factory VoicePack.fromJson(Map<String, Object?> json) {
    final id = _string(json, 'id');
    if (!RegExp(r'^[a-z0-9][a-z0-9._-]{0,127}$').hasMatch(id)) {
      throw FormatException('invalid pack id: $id');
    }
    final version = json['version'] ?? 1;
    if (version is! int) throw const FormatException('version must be an int');
    final files = _list(json, 'files')
        .map((file) => VoicePackFile.fromJson(_map(file, 'files[]')))
        .toList();
    if (files.isEmpty) throw const FormatException('a pack needs files');
    final license = json['license'];
    final config = json['config'];
    return VoicePack(
      id: id,
      name: _optionalString(json, 'name') ?? id,
      version: version,
      modelTypeName: _string(json, 'model_type'),
      languages: List.unmodifiable(_list(json, 'languages').map((language) {
        if (language is! String) {
          throw const FormatException('languages must be strings');
        }
        return language;
      })),
      speakers: List.unmodifiable(
          (json['speakers'] == null ? const [] : _list(json, 'speakers')).map(
              (speaker) =>
                  VoicePackSpeaker.fromJson(_map(speaker, 'speakers[]')))),
      files: List.unmodifiable(files),
      license: license == null
          ? null
          : VoicePackLicense.fromJson(_map(license, 'license')),
      minAppVersion: _optionalString(json, 'min_app_version'),
      config:
          config == null ? const {} : Map.unmodifiable(_map(config, 'config')),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'model_type': modelTypeName,
        'languages': languages,
        'speakers': [for (final speaker in speakers) speaker.toJson()],
        'files': [for (final file in files) file.toJson()],
        if (license != null) 'license': license!.toJson(),
        if (minAppVersion != null) 'min_app_version': minAppVersion,
        if (config.isNotEmpty) 'config': config,
      };

  @override
  String toString() => 'VoicePack($id v$version)';
}

/// The list of voice packs that can be downloaded.
///
/// The catalog is JSON:
///
/// ```json
/// {
///   "schema": 1,
///   "version": 1,
///   "packs": [
///     {
///       "id": "kitten-nano-en",
///       "name": "Kitten nano (English)",
///       "version": 1,
///       "model_type": "kitten",
///       "languages": ["en-US"],
///       "speakers": [{"id": 0, "name": "Jasper", "gender": "male"}],
///       "files": [{
///         "url": "https://…/kitten-nano-en-v0_8-int8.tar.bz2",
///         "size": 31220690,
///         "sha256": "6fa5…",
///         "path": "",
///         "archive": "tar.bz2",
///         "strip_components": 1
///       }],
///       "license": {"name": "Apache-2.0", "url": "…", "attribution": "…"},
///       "min_app_version": "1.0.0",
///       "config": {"model": "model.int8.onnx"}
///     }
///   ]
/// }
/// ```
///
/// Readers ignore fields they don't know, so new fields can be added without
/// bumping [schema]. Packs with a model type or archive format the reader
/// doesn't know stay in [allPacks] but not in [packs]; packs that can't be
/// read at all are dropped. Bump [schema] only for changes old readers would
/// misread; they then reject the whole catalog and fall back to the one
/// they ship with.
@immutable
class VoicePackCatalog {
  /// The newest catalog schema this package reads.
  static const supportedSchema = 1;

  /// The catalog format version.
  final int schema;

  /// The catalog's revision. When two catalogs are available, the one with
  /// the higher version wins.
  final int version;

  /// Every pack that could be read, including unsupported ones.
  final List<VoicePack> allPacks;

  const VoicePackCatalog({
    this.schema = supportedSchema,
    required this.version,
    required this.allPacks,
  });

  /// The packs this package can install.
  List<VoicePack> get packs =>
      allPacks.where((pack) => pack.isSupported).toList();

  /// The pack with [id], or null.
  VoicePack? pack(String id) {
    for (final pack in allPacks) {
      if (pack.id == id) return pack;
    }
    return null;
  }

  /// Parses a catalog from JSON text.
  factory VoicePackCatalog.parse(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException catch (e) {
      throw VoicePackCatalogException('not JSON: ${e.message}');
    }
    if (json is! Map<String, Object?>) {
      throw const VoicePackCatalogException('the catalog must be an object');
    }
    return VoicePackCatalog.fromJson(json);
  }

  factory VoicePackCatalog.fromJson(Map<String, Object?> json) {
    final schema = json['schema'];
    final version = json['version'];
    final packs = json['packs'];
    if (schema is! int || version is! int || packs is! List) {
      throw const VoicePackCatalogException(
          'schema, version and packs are required');
    }
    if (schema > supportedSchema) {
      throw VoicePackCatalogException(
          'schema $schema is newer than $supportedSchema');
    }
    final parsed = <VoicePack>[];
    final ids = <String>{};
    for (final entry in packs) {
      try {
        final pack = VoicePack.fromJson(_map(entry, 'packs[]'));
        // The first of two packs with the same id wins.
        if (ids.add(pack.id)) parsed.add(pack);
      } on FormatException catch (e) {
        debugPrint('skipping a voice pack: ${e.message}');
      }
    }
    return VoicePackCatalog(
        schema: schema, version: version, allPacks: List.unmodifiable(parsed));
  }

  Map<String, Object?> toJson() => {
        'schema': schema,
        'version': version,
        'packs': [for (final pack in allPacks) pack.toJson()],
      };
}

/// Whether [path] is relative and stays inside the directory it's relative
/// to, using `/` as the separator on every platform.
bool isSafeRelativePath(String path) {
  if (path.isEmpty) return true;
  if (path.contains('\\') || path.contains('\x00')) return false;
  if (p.posix.isAbsolute(path) || RegExp(r'^[A-Za-z]:').hasMatch(path)) {
    return false;
  }
  final normalized = p.posix.normalize(path);
  return normalized != '..' && !normalized.startsWith('../');
}

/// Compares dotted version strings such as `1.2.10` and `1.3`: negative
/// when [a] is older than [b], zero when equal, positive when newer.
/// Anything after a `+` or `-` (build or pre-release) is ignored.
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split(RegExp(r'[+-]'))
      .first
      .split('.')
      .map((part) => int.tryParse(part.trim()) ?? 0)
      .toList();
  final x = parts(a), y = parts(b);
  for (var i = 0; i < x.length || i < y.length; i++) {
    final diff = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (diff != 0) return diff;
  }
  return 0;
}

String _normalizeTag(String tag) => tag.replaceAll('_', '-').toLowerCase();

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string');
  }
  return value;
}

String? _optionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('$key must be a string');
  return value;
}

int _int(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer');
  return value;
}

List<Object?> _list(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('$key must be a list');
  return value;
}

Map<String, Object?> _map(Object? value, String name) {
  if (value is! Map<String, Object?>) {
    throw FormatException('$name must be an object');
  }
  return value;
}
