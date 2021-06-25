#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint hermez_sdk.podspec' to validate before publishing.
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
  s.public_header_files = 'Classes**/*.h'
  s.source_files = 'Classes/**/*'
  s.static_framework = true
  s.vendored_libraries = "**/*.a"
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.11'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
