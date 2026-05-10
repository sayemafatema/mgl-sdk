Pod::Spec.new do |s|
  s.name             = 'mgl_fleet_native_sdk'
  s.version          = '0.2.0'
  s.summary          = 'Flutter bridge for MGL Fleet native SDK'
  s.license          = { :type => 'UNLICENSED' }
  s.homepage         = 'https://example.com'
  s.author           = { 'MGL' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'
end
