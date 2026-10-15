Pod::Spec.new do |s|
  s.name             = 'on_device_tts'
  s.version          = '0.1.0'
  s.summary          = 'On-device text-to-speech engines.'
  s.description      = <<-DESC
Neural text-to-speech that runs on the device with ONNX Runtime.
                       DESC
  s.homepage         = 'https://github.com/muxable/rtchat'
  s.license          = { :type => 'Apache-2.0' }
  s.author           = { 'Muxable' => 'https://github.com/muxable' }
  s.source           = { :path => '.' }
  # The only way the app builds this plugin: there is deliberately no
  # on_device_tts/Package.swift for Flutter's Swift Package Manager
  # integration, which embedded ONNX Runtime as a dynamic onnxruntime.framework
  # that App Store Connect rejects (ITMS-90208, see doc/ios.md). With
  # static_framework and the static onnxruntime-c pod, ONNX Runtime is linked
  # into the app binary.
  #
  # The plugin class, plus the engine, which on_device_tts/OnDeviceTtsCore/Package.swift
  # also builds and tests on its own.
  s.source_files = 'on_device_tts/Sources/on_device_tts/**/*.swift',
                   'on_device_tts/OnDeviceTtsCore/Sources/OnDeviceTtsCore/**/*.swift'
  s.dependency 'Flutter'
  # ONNX Runtime (MIT), pinned to the version of Microsoft's Swift package
  # that on_device_tts/OnDeviceTtsCore/Package.swift uses. It needs iOS 15.1.
  s.dependency 'onnxruntime-objc', '1.24.2'
  s.platform = :ios, '15.1'
  s.static_framework = true

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
