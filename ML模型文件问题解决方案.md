# FractureGo ML模型文件问题解决方案

## 问题描述
应用运行时出现"找不到模型文件"的错误，导致MediaPipe姿势检测和手部检测功能无法正常工作。

## 解决方案概述
已经完成以下修复：

1. ✅ 更新了Podfile配置，添加了MediaPipeTasksVision依赖
2. ✅ 重写了MediaPipeService.swift，集成真正的MediaPipe功能
3. ✅ 创建了模型文件管理脚本
4. ✅ 复制了模型文件到正确位置

## 已完成的修复

### 1. Podfile配置
```ruby
platform :ios, '15.0'

target 'FractureGo' do
  use_frameworks!
  
  # MediaPipe依赖
  pod 'MediaPipeTasksVision', '~> 0.10.0'
  # 微信SDK
  pod 'WechatOpenSDK', '~> 2.0.2'
end
```

### 2. MediaPipe服务更新
- 集成了真正的MediaPipe PoseLandmarker和HandLandmarker
- 实现了实际的姿势检测和手部检测功能
- 添加了智能的模型文件路径查找逻辑
- 提供了详细的错误处理和日志输出

### 3. 模型文件管理
- 模型文件已下载到 `MLModels/` 目录
- 已复制到 `FractureGo/MLModels/` 目录
- 文件大小：
  - 姿势检测模型：29MB
  - 手部检测模型：7.5MB

## 当前状态

### ✅ 已完成
- [x] Podfile配置更新
- [x] MediaPipe服务代码重写
- [x] 模型文件下载和复制
- [x] ML测试视图创建

### ⚠️ 需要手动完成
- [ ] 在Xcode中添加模型文件到项目
- [ ] 运行pod install更新依赖
- [ ] 编译并测试应用

## 手动操作步骤

### 步骤1: 更新CocoaPods依赖
```bash
cd /Users/flydinosaur/Codes/Swift/FractureGo
pod install
```

### 步骤2: 在Xcode中添加模型文件
1. 在Xcode中打开 `FractureGo.xcworkspace`（注意是.xcworkspace，不是.xcodeproj）
2. 在项目导航器中右键点击 "FractureGo" 组
3. 选择 "Add Files to 'FractureGo'"
4. 导航到 `FractureGo/MLModels/` 目录
5. 选择以下文件：
   - `pose_landmarker.task`
   - `hand_landmarker.task`
6. 确保勾选 "Add to target: FractureGo"
7. 点击 "Add" 按钮

### 步骤3: 验证模型文件集成
1. 在Xcode项目导航器中确认可以看到两个.task文件
2. 选中项目名称，进入"Build Phases"
3. 展开"Copy Bundle Resources"
4. 确认两个模型文件都在列表中

### 步骤4: 编译和测试
1. 在Xcode中按 Cmd+B 编译项目
2. 如果编译成功，运行应用
3. 导航到ML测试视图验证功能

## 测试ML功能

### 使用MLTestView测试
应用中已包含MLTestView，可以用来测试ML功能：

1. 在应用中找到ML测试页面
2. 查看服务状态（应该显示绿色圆点表示已初始化）
3. 选择一张包含人物或手部的图片
4. 点击"姿势检测"或"手部检测"按钮
5. 查看检测结果

### 预期结果
- 姿势检测：返回33个关键点，包含人体各个关节位置
- 手部检测：返回21个手部关键点，可识别左右手

## 故障排除

### 如果仍然提示找不到模型文件
1. 检查模型文件是否在Bundle Resources中
2. 清理并重新编译项目（Product → Clean Build Folder）
3. 检查Info.plist中的Bundle配置

### 如果MediaPipe初始化失败
1. 确认iOS最低版本设置为15.0
2. 检查设备是否支持Metal
3. 查看Xcode控制台的详细错误信息

### 常见错误解决
- **"Module 'MediaPipeTasksVision' not found"**: 运行 `pod install`
- **"PoseLandmarker/HandLandmarker not found"**: 检查import语句
- **"Model file not found"**: 确认模型文件在Bundle Resources中

## 文件结构

```
FractureGo/
├── FractureGo/
│   ├── Models/
│   │   ├── MediaPipeService.swift (已更新)
│   │   ├── MLServiceProtocols.swift
│   │   └── MLServiceFactory.swift
│   ├── Views/
│   │   └── MLTestView.swift (测试界面)
│   └── MLModels/ (新增)
│       ├── pose_landmarker.task
│       └── hand_landmarker.task
├── MLModels/ (原始文件)
│   ├── PoseDetection/
│   │   └── pose_landmarker.task
│   └── HandDetection/
│       └── hand_landmarker.task
├── Podfile (已更新)
├── download_models.sh
└── setup_models.sh
```

## 技术细节

### MediaPipe集成特点
- 使用MediaPipe Tasks Vision 0.10.21版本
- 支持实时图像和视频流检测
- 提供高精度的姿势和手部关键点检测
- 包含置信度和可见性信息

### 性能优化
- 模型在应用启动时预加载
- 使用后台队列进行推理计算
- 支持批量处理提高效率

## 下一步建议

1. 完成手动步骤后测试基本功能
2. 根据应用需求调整检测参数
3. 实现特定的康复动作识别算法
4. 添加实时相机检测功能
5. 优化性能和用户体验

## 支持

如果遇到问题，请检查：
1. Xcode控制台的错误日志
2. 模型文件是否正确添加到项目
3. CocoaPods依赖是否正确安装
4. 设备是否满足最低系统要求（iOS 15.0+） 