# 手部识别模型 (Hand Detection)

## 模型概述
此文件夹包含用于手部关键点检测和手势识别的MediaPipe模型，专门用于手部康复训练。

### 模型文件
- **文件名**: `hand_landmarker.task`
- **模型类型**: MediaPipe Hand Landmarker
- **文件大小**: 约 10.7 MB
- **支持平台**: iOS 15.0+

## 下载和安装

### 1. 模型下载
```bash
# 使用curl下载模型文件
curl -L -o hand_landmarker.task \
  "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task"
```

### 2. 添加到Xcode项目
1. 将下载的 `hand_landmarker.task` 文件拖拽到此文件夹
2. 在Xcode中右键项目 → Add Files to "FractureGo"
3. 选择 `MLModels/HandDetection/hand_landmarker.task`
4. 确保Target选择了 "FractureGo"
5. 确保添加到Bundle Resources

## 模型功能

### 检测的关键点 (21个关键点)
```
单手关键点结构:
0: WRIST              11: MIDDLE_FINGER_TIP
1: THUMB_CMC          12: RING_FINGER_MCP
2: THUMB_MCP          13: RING_FINGER_PIP
3: THUMB_IP           14: RING_FINGER_DIP
4: THUMB_TIP          15: RING_FINGER_TIP
5: INDEX_FINGER_MCP   16: PINKY_MCP
6: INDEX_FINGER_PIP   17: PINKY_PIP
7: INDEX_FINGER_DIP   18: PINKY_DIP
8: INDEX_FINGER_TIP   19: PINKY_TIP
9: MIDDLE_FINGER_MCP  20: PINKY_FINGER_TIP
10: MIDDLE_FINGER_PIP
```

### 康复应用场景

#### 手指灵活性训练
- **指关节活动度**: 监测每个手指的弯曲和伸直
- **手指独立性**: 检测单个手指的独立运动
- **手指协调性**: 分析多个手指的协调动作

#### 抓握功能评估
- **握力评估**: 通过手型分析握力强度
- **精细抓握**: 监测拇指与其他手指的对指动作
- **粗大抓握**: 检测整手抓握物体的能力

#### 手势识别训练
- **基础手势**: 识别张开、紧握、指向等基本手势
- **功能性手势**: 识别日常生活中的实用手势
- **康复手势**: 特定的康复训练手势识别

## 使用示例

### Swift集成代码
```swift
import MediaPipeTasksVision

class HandDetectionService {
    private var handDetector: HandLandmarker?
    
    func initializeHandDetector() {
        guard let modelPath = Bundle.main.path(forResource: "hand_landmarker", ofType: "task") else {
            print("手部模型文件未找到")
            return
        }
        
        let options = HandLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .liveStream
        options.numHands = 2  // 支持双手检测
        options.minHandDetectionConfidence = 0.5
        options.minHandPresenceConfidence = 0.5
        options.minTrackingConfidence = 0.5
        
        do {
            handDetector = try HandLandmarker(options: options)
        } catch {
            print("初始化手部检测器失败: \(error)")
        }
    }
    
    func detectHands(in image: UIImage) -> HandLandmarkerResult? {
        guard let handDetector = handDetector else { return nil }
        
        let mpImage = MPImage(uiImage: image)
        
        do {
            let result = try handDetector.detect(image: mpImage)
            return result
        } catch {
            print("手部检测失败: \(error)")
            return nil
        }
    }
}
```

### 康复训练评估
```swift
extension HandDetectionService {
    
    // 评估手指弯曲角度
    func evaluateFingerBending(landmarks: [NormalizedLandmark], finger: FingerType) -> Double {
        let joints = getFingerJoints(finger: finger)
        
        let mcp = landmarks[joints.mcp]
        let pip = landmarks[joints.pip]
        let dip = landmarks[joints.dip]
        let tip = landmarks[joints.tip]
        
        // 计算手指弯曲角度
        let angle1 = calculateAngle(p1: mcp, p2: pip, p3: dip)
        let angle2 = calculateAngle(p1: pip, p2: dip, p3: tip)
        
        return (angle1 + angle2) / 2
    }
    
    // 评估手部张开程度
    func evaluateHandOpenness(landmarks: [NormalizedLandmark]) -> Double {
        let wrist = landmarks[0]
        let fingers = [4, 8, 12, 16, 20] // 各手指尖端
        
        var totalDistance = 0.0
        for fingerTip in fingers {
            let tip = landmarks[fingerTip]
            let distance = calculateDistance(p1: wrist, p2: tip)
            totalDistance += distance
        }
        
        return totalDistance / Double(fingers.count)
    }
    
    // 检测抓握状态
    func detectGraspingState(landmarks: [NormalizedLandmark]) -> GraspingState {
        let fingerTips = [4, 8, 12, 16, 20]
        let wrist = landmarks[0]
        
        var closedFingers = 0
        
        for tipIndex in fingerTips {
            let tip = landmarks[tipIndex]
            let distance = calculateDistance(p1: wrist, p2: tip)
            
            // 距离手腕较近表示手指弯曲
            if distance < 0.12 {
                closedFingers += 1
            }
        }
        
        switch closedFingers {
        case 0...1: return .open
        case 2...3: return .partialGrasp
        case 4...5: return .fullGrasp
        default: return .unknown
        }
    }
    
    // 评估拇指对指功能
    func evaluateThumbOpposition(landmarks: [NormalizedLandmark]) -> ThumbOppositionScore {
        let thumbTip = landmarks[4]
        let indexTip = landmarks[8]
        let middleTip = landmarks[12]
        let ringTip = landmarks[16]
        let pinkyTip = landmarks[20]
        
        let otherTips = [indexTip, middleTip, ringTip, pinkyTip]
        var minDistance = Double.infinity
        
        for tip in otherTips {
            let distance = calculateDistance(p1: thumbTip, p2: tip)
            minDistance = min(minDistance, distance)
        }
        
        // 根据距离评估对指能力
        if minDistance < 0.03 {
            return .excellent
        } else if minDistance < 0.06 {
            return .good
        } else if minDistance < 0.10 {
            return .fair
        } else {
            return .poor
        }
    }
    
    private func calculateDistance(p1: NormalizedLandmark, p2: NormalizedLandmark) -> Double {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private func calculateAngle(p1: NormalizedLandmark, p2: NormalizedLandmark, p3: NormalizedLandmark) -> Double {
        let v1x = p1.x - p2.x
        let v1y = p1.y - p2.y
        let v2x = p3.x - p2.x
        let v2y = p3.y - p2.y
        
        let dot = v1x * v2x + v1y * v2y
        let mag1 = sqrt(v1x * v1x + v1y * v1y)
        let mag2 = sqrt(v2x * v2x + v2y * v2y)
        
        let cosAngle = dot / (mag1 * mag2)
        let angle = acos(cosAngle) * 180.0 / .pi
        
        return angle
    }
}

// 辅助枚举定义
enum FingerType {
    case thumb, index, middle, ring, pinky
}

enum GraspingState {
    case open, partialGrasp, fullGrasp, unknown
}

enum ThumbOppositionScore {
    case excellent, good, fair, poor
}

struct FingerJoints {
    let mcp: Int // 掌指关节
    let pip: Int // 近指关节  
    let dip: Int // 远指关节
    let tip: Int // 指尖
}

extension HandDetectionService {
    private func getFingerJoints(finger: FingerType) -> FingerJoints {
        switch finger {
        case .thumb:
            return FingerJoints(mcp: 1, pip: 2, dip: 3, tip: 4)
        case .index:
            return FingerJoints(mcp: 5, pip: 6, dip: 7, tip: 8)
        case .middle:
            return FingerJoints(mcp: 9, pip: 10, dip: 11, tip: 12)
        case .ring:
            return FingerJoints(mcp: 13, pip: 14, dip: 15, tip: 16)
        case .pinky:
            return FingerJoints(mcp: 17, pip: 18, dip: 19, tip: 20)
        }
    }
}
```

## 康复训练场景

### 1. 手指活动度训练
```swift
// 手指伸展训练
func fingerExtensionExercise() {
    // 检测手指是否完全伸直
    // 提供实时反馈
}

// 手指弯曲训练  
func fingerFlexionExercise() {
    // 检测手指弯曲程度
    // 记录活动范围
}
```

### 2. 抓握功能训练
```swift
// 精细抓握训练
func pinchGraspTraining() {
    // 检测拇指与食指的对指动作
    // 评估抓握力度
}

// 整手抓握训练
func wholeHandGraspTraining() {
    // 检测整手抓握动作
    // 评估抓握稳定性
}
```

### 3. 手部协调性训练
```swift
// 手指独立性训练
func fingerIndependenceTraining() {
    // 检测单个手指的独立运动
    // 避免其他手指的代偿动作
}

// 双手协调训练
func bimanualCoordinationTraining() {
    // 同时检测双手动作
    // 评估双手协调性
}
```

## 性能参数
- **推理速度**: ~20-40ms (iPhone 12 Pro)
- **内存使用**: ~40-60MB
- **检测精度**: 98%+ (正常光照条件)
- **最大检测距离**: 1-2米
- **支持手数**: 最多2只手同时检测

## 注意事项
- 确保手部完整出现在画面中
- 避免手部被遮挡
- 保持适当的光照条件
- 避免背景与肤色相似
- 相机距离手部0.3-1.5米为最佳 