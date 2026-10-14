#!/usr/bin/env ruby
# Local-only SDK-1338 compatibility build. No upload or spec publication.
require 'xcodeproj'
require 'fileutils'
require 'json'
require 'yaml'

root = File.expand_path('..', __dir__)
export = File.expand_path(ARGV.fetch(0))
version = '3.8.0.4-bmplus.1'
output = File.join(root, 'build', 'bidmachine-bidon015')
FileUtils.mkdir_p(output)
lock = YAML.load_file(File.join(export, 'Podfile.lock'))
pods = lock.fetch('PODS').map { |p| p.is_a?(Hash) ? p.keys.first : p }
abort 'Expected installed Bidon 0.15.0' unless pods.include?('Bidon (0.15.0)')
abort 'Expected installed BidMachine/Static 3.8.0' unless pods.include?('BidMachine/Static (3.8.0)')
abort 'Pod lock differs from installed manifest' unless File.binread(File.join(export, 'Podfile.lock')) == File.binread(File.join(export, 'Pods/Manifest.lock'))

frameworks = {
  'Bidon' => File.join(export, 'Pods/Bidon/Bidon-0.15.0/Bidon.xcframework'),
  'BidMachine' => File.join(export, 'Pods/BidMachine/release/Static/BidMachine.xcframework'),
  'OMSDK_Appodeal' => File.join(export, 'Pods/OMSDK_Appodeal/release/Static/OMSDK_Appodeal.xcframework')
}
{'iphoneos' => 'ios-arm64', 'iphonesimulator' => 'ios-arm64_x86_64-simulator'}.each do |sdk, slice|
  frameworks.each do |name, xcframework|
    source = File.join(xcframework, slice, "#{name}.framework")
    abort "Missing #{source}" unless File.directory?(source)
    dest = File.join(output, 'dependencies', sdk)
    FileUtils.mkdir_p(dest)
    target = File.join(dest, "#{name}.framework")
    FileUtils.rm_rf(target) if File.exist?(target)
    FileUtils.cp_r(source, target)
  end
end
project_path = File.join(output, 'Compatibility.xcodeproj')
FileUtils.rm_rf(project_path) if File.exist?(project_path)
project = Xcodeproj::Project.new(project_path)
adapter = project.new_target(:framework, 'BidonAdapterBidMachine', :ios, '13.0')
Dir.glob(File.join(root, 'Adapters/BidonAdapterBidMachine/**/*.{swift,h,m}')).sort.each do |path|
  ref = project.main_group.new_file(path)
  if File.extname(path) == '.h'
    adapter.headers_build_phase.add_file_reference(ref).settings = {'ATTRIBUTES' => ['Public']}
  else
    adapter.source_build_phase.add_file_reference(ref)
  end
end
adapter.build_configurations.each do |config|
  config.build_settings.merge!({
    'MACH_O_TYPE' => 'staticlib', 'DEFINES_MODULE' => 'YES',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES', 'SKIP_INSTALL' => 'NO',
    'SWIFT_VERSION' => '5.0', 'SWIFT_INSTALL_OBJC_HEADER' => 'YES',
    'GENERATE_INFOPLIST_FILE' => 'YES', 'PRODUCT_BUNDLE_IDENTIFIER' => 'org.bidon.BidonAdapterBidMachine',
    'MARKETING_VERSION' => '3.8.0', 'CURRENT_PROJECT_VERSION' => '4',
    'CODE_SIGNING_ALLOWED' => 'NO', 'ONLY_ACTIVE_ARCH' => 'NO',
    'FRAMEWORK_SEARCH_PATHS' => ['$(inherited)', '$(PROJECT_DIR)/dependencies/$(PLATFORM_NAME)']
  })
  config.build_settings['ENABLE_TESTABILITY'] = config.name == 'Debug' ? 'YES' : 'NO'
end

tests = project.new_target(:unit_test_bundle, 'BidMachineCompatibilityTests', :ios, '15.0')
ref = project.main_group.new_file(File.join(root, 'Tests/AdaptersTests/BidonAdapterBidMachineTests/BidMachineMediationModeTests.swift'))
tests.source_build_phase.add_file_reference(ref)
tests.add_dependency(adapter)
tests.frameworks_build_phase.add_file_reference(adapter.product_reference)
tests.build_configurations.each do |config|
  config.build_settings.merge!({
    'SWIFT_VERSION' => '5.0', 'GENERATE_INFOPLIST_FILE' => 'YES',
    'PRODUCT_BUNDLE_IDENTIFIER' => 'org.bidon.BidMachineCompatibilityTests',
    'CODE_SIGNING_ALLOWED' => 'NO', 'TEST_HOST' => '',
    'FRAMEWORK_SEARCH_PATHS' => ['$(inherited)', '$(BUILT_PRODUCTS_DIR)', '$(PROJECT_DIR)/dependencies/$(PLATFORM_NAME)'],
    'OTHER_LDFLAGS' => ['$(inherited)', '-ObjC', '-framework', 'Bidon', '-framework', 'BidMachine', '-framework', 'OMSDK_Appodeal', '-lxml2', '-lsqlite3', '-lz', '-lc++']
  })
end
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(adapter)
scheme.add_test_target(tests)
scheme.test_action.build_configuration = 'Debug'
scheme.save_as(project_path, 'BidonAdapterBidMachine', true)

artifact = File.join(output, "BidonAdapterBidMachine-#{version}")
FileUtils.mkdir_p(artifact)
spec = {
  'name' => 'BidonAdapterBidMachine', 'version' => version,
  'summary' => 'BidMachine adapter with SDK-1338 for Bidon 0.15.0',
  'homepage' => 'https://bidon.org',
  'license' => {'type' => 'Copyright', 'text' => 'Copyright 2026. Bidon Inc.'},
  'authors' => {'Bidon Inc.' => 'https://bidon.org'},
  'platforms' => {'ios' => '13.0'},
  'source' => {'http' => "https://s3-eu-central-1.amazonaws.com/bidon-ios/BidonAdapterBidMachine/#{version}/BidonAdapterBidMachine.zip"},
  'swift_versions' => ['5.0'], 'default_subspecs' => 'Static',
  'user_target_xcconfig' => {'OTHER_LDFLAGS' => '$(inherited) -ObjC'},
  'subspecs' => %w[Static Dynamic].map do |linkage|
    {'name' => linkage, 'vendored_frameworks' => ['BidonAdapterBidMachine.xcframework'],
     'dependencies' => {'Bidon' => ['= 0.15.0'], "BidMachine/#{linkage}" => ['= 3.8.0']}}
  end
}
File.write(File.join(artifact, 'BidonAdapterBidMachine.podspec.json'), JSON.pretty_generate(spec) + "\n")
File.write(File.join(output, 'build-inputs.json'), JSON.pretty_generate({version: version, bidon: '0.15.0', bidmachine: '3.8.0', export: export, publication: 'none'}) + "\n")
puts output
