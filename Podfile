# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'FractureGo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for FractureGo
  pod 'MediaPipeTasksVision', '~> 0.10.0'
  
  # 微信SDK
  pod 'WechatOpenSDK', '~> 2.0.2'
  
  # 如果需要其他依赖，可以在这里添加
  # pod 'Alamofire' # 网络请求（如需要）

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['OTHER_LDFLAGS'] = '-ObjC'
      
      # MediaPipe特定配置
      if target.name.start_with?('MediaPipe')
        config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
        config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      end
    end
  end
end