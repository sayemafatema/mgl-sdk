require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = 'MglFleetSdk'
  s.version      = package['version']
  s.summary      = package['description']
  s.homepage     = package['homepage']
  s.license      = package['license']
  s.author       = 'MGL'
  s.platform     = :ios, '16.0'
  s.source       = { :git => 'https://github.com/YOUR_ORG/mgl-sdk.git', :tag => package['version'].to_s }
  s.source_files = 'ios/**/*.{m,mm,swift}'
  s.swift_version = '5.9'

  s.dependency 'React-Core'
end
