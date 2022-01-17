#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run 'pod lib lint hermez_sdk.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'hermez_sdk'
  s.version          = '1.0.0'
  s.summary          = 'Flutter Plugin for Hermez SDK'
  s.description      = <<-DESC
Hermez library flutter plugin project.
                       DESC
  s.homepage         = 'https://hermez.io'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Hermez'
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.static_framework = true
  s.vendored_libraries = "**/*.a"
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'STRIP_STYLE' => 'non-global', 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
