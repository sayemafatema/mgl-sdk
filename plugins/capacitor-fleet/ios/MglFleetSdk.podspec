Pod::Spec.new do |s|
  s.name = 'MglFleetSdk'
  s.version = '0.3.0'
  s.summary = 'Capacitor bridge for MGL Fleet native SDK'
  s.license = { :type => 'Apache License, Version 2.0' }
  s.homepage = 'https://github.com/YOUR_ORG/mgl-sdk/tree/main/plugins/capacitor-fleet'
  s.author = 'MGL'
  # CocoaPods resolves this podspec from `plugins/capacitor-fleet/ios/` inside the npm tarball after `npm install`.
  s.source = { :path => '.' }
  s.source_files = 'Plugin/**/*.{swift}'
  s.ios.deployment_target = '16.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.9'
end
