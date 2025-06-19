# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'FractureGo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for FractureGo
  
  # MediaPipe Tasks for computer vision
  pod 'MediaPipeTasksVision', '~> 0.10.0'
  
  # Additional dependencies for ML and vision processing
  pod 'GoogleMLKit/PoseDetection', '~> 4.0.0'

end

# Post-install script to ensure compatibility
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      
      # Fix for MediaPipe compilation issues
      if target.name == 'MediaPipeTasksVision'
        config.build_settings['ENABLE_BITCODE'] = 'NO'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      end
    end
  end
end 