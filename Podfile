# Uncomment the next line to define a global platform for your project

platform :ios, "11.0"

target 'AI_Message' do
    pod 'BMSCore', '~> 2.0'
    
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!

  # Pods for AI_Message

pod 'Firebase/Core'
pod 'Firebase/Auth'
pod 'Firebase/Database'
pod 'Firebase/Storage', '4.8.2'
pod 'MessageKit', '0.13.1'
pod 'Firebase/Firestore'
pod 'IBMWatsonVisualRecognitionV3', '~> 0.35.0'
pod 'SVProgressHUD'
pod 'NVActivityIndicatorView'
pod 'IBMWatsonAssistantV1', '~> 0.35.0'

post_install do |installer|
      installer.pods_project.targets.each do |target|
          if target.name == 'MessageKit' || 'IBMWatsonVisualRecognitionV3' || 'SVProgressHUD'
              target.build_configurations.each do |config|
                  config.build_settings['SWIFT_VERSION'] = '4.0'
              end
          end
      end
  end


end
