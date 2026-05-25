require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name           = 'Visara'
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = package['description']
  s.homepage       = 'https://github.com/harshithharijeevan/visara'
  s.license        = package['license']
  s.author         = package['author']
  s.platforms      = { :ios => '16.0' }
  s.source         = { :path => '.' }

  s.source_files = [
    'ios/**/*.swift',
    'scanner/**/*.swift',
    'providers/**/*.swift',
    'models/**/*.swift'
  ]

  s.exclude_files = [
    'tests/**'
  ]

  s.dependency 'ExpoModulesCore'
end
