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
  s.source_files = 'on_device_tts/Sources/on_device_tts/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
