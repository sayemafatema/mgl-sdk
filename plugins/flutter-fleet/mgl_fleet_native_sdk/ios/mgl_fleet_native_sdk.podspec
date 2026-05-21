Pod::Spec.new do |s|
  s.name             = 'mgl_fleet_native_sdk'
  s.version          = '0.5.0'
  s.summary          = 'Flutter bridge for MGL Fleet native SDK (Android + iOS parity)'
  s.license          = { :type => 'Apache-2.0' }
  s.homepage         = 'https://github.com/YOUR_ORG/mgl-sdk'
  s.author           = { 'MGL' => 'sdk@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '16.0'
  s.swift_version    = '5.9'

  # Links native-ios/MGLFleetSDK when integrating from the monorepo (path/git dependency).
  # Published consumers without this path must add MGLFleetSDK to Runner (SPM) — see README.
  native_sdk_path = File.expand_path('../../../../native-ios/MGLFleetSDK', __dir__)
  if File.directory?(native_sdk_path)
    s.dependency 'MGLFleetSDK', :path => native_sdk_path
  end
end
