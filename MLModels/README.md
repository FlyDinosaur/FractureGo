# 机器学习模型文件夹

此文件夹用于存放FractureGo应用所需的机器学习模型文件。

## 文件夹结构

```
MLModels/
├── PoseDetection/              # 姿势识别模型
│   ├── pose_landmarker.task    # MediaPipe姿势识别模型文件
│   └── README.md              # 姿势识别模型说明
├── HandDetection/              # 手部识别模型  
│   ├── hand_landmarker.task    # MediaPipe手部识别模型文件
│   └── README.md              # 手部识别模型说明
└── README.md                  # 本文件
```

## 模型用途

### 姿势识别 (PoseDetection)
- **用途**: 识别用户身体姿势，用于腿部和手臂康复训练动作检测
- **模型**: MediaPipe Pose Landmarker
- **支持功能**: 
  - 关节点检测
  - 姿势分类
  - 动作轨迹跟踪
  - 康复动作准确性评估

### 手部识别 (HandDetection)  
- **用途**: 识别手部动作和手指活动，用于手部康复训练
- **模型**: MediaPipe Hand Landmarker
- **支持功能**:
  - 手部关键点检测
  - 手势识别
  - 手指灵活性评估
  - 抓握力度分析

## 模型下载说明

### MediaPipe预训练模型下载地址：

1. **姿势识别模型**:
   - 下载地址: https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/1/pose_landmarker_heavy.task
   - 文件名: `pose_landmarker.task`
   - 存放位置: `MLModels/PoseDetection/`

2. **手部识别模型**:
   - 下载地址: https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task
   - 文件名: `hand_landmarker.task`
   - 存放位置: `MLModels/HandDetection/`

## 模型集成到Xcode项目

1. 将下载的模型文件拖拽到对应的文件夹中
2. 在Xcode中将模型文件添加到项目中
3. 确保模型文件的Target Membership包含FractureGo
4. 在Bundle Resources中确认模型文件被正确包含

## 使用示例

```swift
// 初始化姿势识别器
let poseDetector = PoseDetector()
let poseModelPath = Bundle.main.path(forResource: "pose_landmarker", ofType: "task")

// 初始化手部识别器  
let handDetector = HandDetector()
let handModelPath = Bundle.main.path(forResource: "hand_landmarker", ofType: "task")
```

## 注意事项

- 模型文件较大，请确保设备有足够存储空间
- 首次加载模型可能需要一些时间
- 建议在WiFi环境下下载模型文件
- 模型文件不应提交到Git仓库中（已添加到.gitignore）

## 性能优化建议

- 在应用启动时预加载模型
- 使用后台队列进行模型推理
- 适当降低相机分辨率以提高性能
- 考虑使用模型量化版本以减少内存占用 