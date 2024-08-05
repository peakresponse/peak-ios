# Uncomment the next line to define a global platform for your project
platform :ios, '15.5'

plugin 'cocoapods-keys', {
  :project => 'Triage',
  :keys => [
    'ApiClientServerUrl',
    'GoogleMapsSdkApiKey',
    'RollbarEnvironment',
    'RollbarPostClientItemAccessToken'
  ]
}

target 'Triage' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Triage
  pod 'Google-Maps-iOS-Utils'
  pod 'GoogleMaps'
  pod 'GoogleMLKit/BarcodeScanning', '3.2.0'
  pod 'ICD10Kit'
  pod 'PRKit', :git => 'https://github.com/peakresponse/peak-ios-prkit.git', :branch => '358-dark'
  pod 'RealmSwift', '~> 10.43'
  pod 'RollbarNotifier', '~> 3.2'
  pod 'RxNormKit'
  pod 'RMJSONPatch', '1.0.4'
  pod 'Starscream'
  pod 'SwiftLint'
  pod 'SwiftPath'
  pod 'SNOMEDKit'
  pod 'TranscriptionKit', :git => 'https://github.com/peakresponse/peak-ios-transcriptionkit.git', :branch => 'dev'

  target 'TriageTests' do
    inherit! :search_paths
    # Pods for testing
  end
end

# move UITests target out of main target to fix build issues as per
# https://github.com/CocoaPods/CocoaPods/issues/5250#issuecomment-642289880
target 'TriageUITests' do
  inherit! :search_paths
  # Pods for testing
end

# remove deployment target setting from pods
# https://www.jessesquires.com/blog/2020/07/20/xcode-12-drops-support-for-ios-8-fix-for-cocoapods/
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
