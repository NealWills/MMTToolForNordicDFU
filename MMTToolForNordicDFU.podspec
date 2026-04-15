#
# Be sure to run `pod lib lint MMTToolForNordicDFU.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MMTToolForNordicDFU'
  s.version          = '0.6.1'
  s.summary          = 'A tool for Nordic Device Firmware Update (DFU) over Bluetooth.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
MMTToolForNordicDFU provides a comprehensive solution for performing Device Firmware Update (DFU) 
on Nordic Semiconductor devices over Bluetooth Low Energy (BLE). It simplifies the DFU process 
with features including firmware package validation, progress tracking, and error handling. 
The library supports ZIP-based firmware distribution and integrates seamlessly with iOS Bluetooth framework.
                       DESC

  s.homepage         = 'https://github.com/NealWills/MMTToolForNordicDFU'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'NealWills' => 'aoiiiiyuki@outlook.com' }
  s.source           = { :git => 'https://github.com/NealWills/MMTToolForNordicDFU.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'MMTToolForNordicDFU/Classes/**/*'
  
  # s.resource_bundles = {
  #   'MMTToolForNordicDFU' => ['MMTToolForNordicDFU/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  
  s.frameworks = 'CoreBluetooth'
  s.dependency 'ZIPFoundation'
  
end
