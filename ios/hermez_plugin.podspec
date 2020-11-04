#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint hermez_plugin.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'hermez_plugin'
  s.version          = '0.0.1'
  s.summary          = 'Hermez library flutter plugin project.'
  s.description      = <<-DESC
Hermez library flutter plugin project.
                       DESC
  s.homepage         = 'https://hermez.io'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Hermez' }
  s.source           = { :path => '.' }
  s.public_header_files = 'Classes**/*.h'
  s.source_files = 'Classes/**/*'
  s.static_framework = true
  s.vendored_libraries = "**/*.a"
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
