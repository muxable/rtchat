import 'package:flutter/foundation.dart';

/// How much memory the device has, from the native engine's `deviceMemory`
/// call (see `doc/native_contract.md`).
@immutable
class DeviceMemory {
  /// The memory the kernel can use (Android's `MemoryInfo.totalMem`), a bit
  /// less than the RAM on the box: a "3 GB" phone reports about 2.8 GiB.
  final int totalBytes;

  /// The memory available right now, as the platform estimates it.
  final int? availableBytes;

  /// Whether the platform calls this a low-RAM device (Android's
  /// `ActivityManager.isLowRamDevice()`, e.g. Android Go phones).
  final bool isLowRamDevice;

  const DeviceMemory({
    required this.totalBytes,
    this.availableBytes,
    this.isLowRamDevice = false,
  });

  factory DeviceMemory.fromMap(Map<Object?, Object?> map) => DeviceMemory(
        totalBytes: (map['totalBytes'] as num).toInt(),
        availableBytes: (map['availableBytes'] as num?)?.toInt(),
        isLowRamDevice: map['lowRamDevice'] as bool? ?? false,
      );

  /// Below this much total memory, neural voices don't load on their own.
  ///
  /// Supertonic 3 (fp32) peaks at 290 to 620 MB of resident memory while it
  /// loads and synthesizes. On a 2 GB phone that is a quarter of the RAM,
  /// next to a streaming app that is encoding video: the system kills the
  /// app (and with it, chat reading) or the streaming app. Phones sold as
  /// 3 GB report about 2.8 GiB and are allowed; if the model fails to load
  /// there, the app falls back to the system voices anyway.
  static const minimumBytesForNeuralTts = 2560 * 1024 * 1024; // 2.5 GiB

  /// Whether the device has too little memory to load a neural model
  /// without being asked: a low-RAM device, or less than
  /// [minimumBytesForNeuralTts] in all.
  bool get isTooSmallForNeuralTts =>
      isLowRamDevice || totalBytes < minimumBytesForNeuralTts;

  @override
  bool operator ==(Object other) =>
      other is DeviceMemory &&
      other.totalBytes == totalBytes &&
      other.availableBytes == availableBytes &&
      other.isLowRamDevice == isLowRamDevice;

  @override
  int get hashCode => Object.hash(totalBytes, availableBytes, isLowRamDevice);

  @override
  String toString() => 'DeviceMemory(${totalBytes >> 20} MiB total'
      '${availableBytes == null ? '' : ', ${availableBytes! >> 20} MiB free'}'
      '${isLowRamDevice ? ', low-RAM device' : ''})';
}
