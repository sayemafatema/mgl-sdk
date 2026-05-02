Pod::Spec.new do |s|
  s.name             = 'MGLFleetSDK'
  s.version          = '0.1.0'
  s.summary          = 'Native iOS Fleet SDK (Swift)'
  s.description      = 'MGL Fleet fullscreen native flow + API client. Used by Capacitor / Flutter / RN bridges.'
  s.homepage         = 'https://github.com/YOUR_ORG/mgl-sdk'
  # LICENSE path is relative to the repo root when sourcing via :git above.
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'native-ios/MGLFleetSDK/LICENSE' }
  s.author           = { 'MGL' => 'sdk@example.com' }

  # Replace YOUR_ORG and tag before `pod trunk push`. Tag monorepo or subtree as needed.
  s.source           = {
    :git => 'https://github.com/YOUR_ORG/mgl-sdk.git',
    :tag => '0.1.0'
  }

  s.swift_version    = '5.9'
  s.platform         = :ios, '15.0'

  # Paths relative to repo root when sourcing from monorepo tag above.
  s.source_files     = 'native-ios/MGLFleetSDK/Sources/MGLFleetSDK/**/*.{swift}'
  s.exclude_files    = 'native-ios/MGLFleetSDK/Sources/**/*.plist'
end
