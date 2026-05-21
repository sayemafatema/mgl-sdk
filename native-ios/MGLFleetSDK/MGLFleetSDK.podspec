Pod::Spec.new do |s|
  s.name             = 'MGLFleetSDK'
  s.version          = '0.3.0'
  s.summary          = 'Native iOS Fleet SDK (Swift)'
  s.description      = 'MGL Fleet fullscreen native flow + API client. Used by Capacitor / Flutter / RN bridges.'
  s.homepage         = 'https://github.com/YOUR_ORG/mgl-sdk'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author           = { 'MGL' => 'sdk@example.com' }

  # Replace YOUR_ORG and tag before `pod trunk push`.
  s.source           = {
    :git => 'https://github.com/YOUR_ORG/mgl-sdk.git',
    :tag => s.version.to_s,
  }

  s.swift_version    = '5.9'
  s.platform         = :ios, '16.0'

  # Paths are relative to this podspec directory (local :path or monorepo git checkout).
  s.source_files     = 'Sources/MGLFleetSDK/**/*.swift'
  s.resource_bundles = { 'MGLFleetSDK' => ['Sources/MGLFleetSDK/Resources/*'] }
end
