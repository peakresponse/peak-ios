# Uncomment the next line to define a global platform for your project
platform :ios, '12.4'

plugin 'cocoapods-keys', {
  :project => 'Triage',
  :keys => [
    'ApiClientServerUrl',
    'GoogleMapsSdkApiKey'
  ]
}

target 'Triage' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Triage
  pod 'Google-Maps-iOS-Utils'
  pod 'GoogleMaps'
  pod 'RealmSwift'
  pod 'Starscream'
  pod 'SwiftLint'

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
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
