# 姿势识别模型 (Pose Detection)

## 模型概述
此文件夹包含用于身体姿势检测和康复动作分析的MediaPipe模型。

### 模型文件
- **文件名**: `pose_landmarker.task`
- **模型类型**: MediaPipe Pose Landmarker (Heavy版本)
- **文件大小**: 约 12.3 MB
- **支持平台**: iOS 15.0+

## 下载和安装

### 1. 模型下载
```bash
# 使用curl下载模型文件
curl -L -o pose_landmarker.task \
  "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/1/pose_landmarker_heavy.task"
```

### 2. 添加到Xcode项目
1. 将下载的 `pose_landmarker.task` 文件拖拽到此文件夹
2. 在Xcode中右键项目 → Add Files to "FractureGo"
3. 选择 `MLModels/PoseDetection/pose_landmarker.task`
4. 确保Target选择了 "FractureGo"
5. 确保添加到Bundle Resources

## 模型功能

### 检测的关键点 (33个关键点)
```
0: NOSE                    17: LEFT_PINKY
1: LEFT_EYE_INNER         18: RIGHT_PINKY  
2: LEFT_EYE               19: LEFT_INDEX
3: LEFT_EYE_OUTER         20: RIGHT_INDEX
4: RIGHT_EYE_INNER        21: LEFT_THUMB
5: RIGHT_EYE              22: RIGHT_THUMB
6: RIGHT_EYE_OUTER        23: LEFT_HIP
7: LEFT_EAR               24: RIGHT_HIP
8: RIGHT_EAR              25: LEFT_KNEE
9: MOUTH_LEFT             26: RIGHT_KNEE
10: MOUTH_RIGHT           27: LEFT_ANKLE
11: LEFT_SHOULDER         28: RIGHT_ANKLE
12: RIGHT_SHOULDER        29: LEFT_HEEL
13: LEFT_ELBOW            30: RIGHT_HEEL
14: RIGHT_ELBOW           31: LEFT_FOOT_INDEX
15: LEFT_WRIST            32: RIGHT_FOOT_INDEX
16: RIGHT_WRIST
```

### 康复应用场景

#### 手臂康复训练
- **肩关节活动度检测**: 监测肩膀抬举角度
- **肘关节屈伸**: 检测肘部弯曲和伸直动作
- **手臂协调性**: 分析双臂同步运动

#### 腿部康复训练  
- **膝关节活动**: 监测膝盖弯曲和伸直
- **髋关节稳定性**: 检测髋部平衡
- **步态分析**: 行走姿势评估

#### 全身姿势评估
- **脊柱对齐**: 检测身体直立度
- **重心平衡**: 分析身体重心分布
- **对称性评估**: 左右肢体对称性检查

## 使用示例

### Swift集成代码
```swift
import MediaPipeTasksVision

class PoseDetectionService {
    private var poseDetector: PoseLandmarker?
    
    func initializePoseDetector() {
        guard let modelPath = Bundle.main.path(forResource: "pose_landmarker", ofType: "task") else {
            print("模型文件未找到")
            return
        }
        
        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .liveStream
        options.numPoses = 1
        options.minPoseDetectionConfidence = 0.5
        options.minPosePresenceConfidence = 0.5
        options.minTrackingConfidence = 0.5
        
        do {
            poseDetector = try PoseLandmarker(options: options)
        } catch {
            print("初始化姿势检测器失败: \(error)")
        }
    }
    
    func detectPose(in image: UIImage) -> PoseLandmarkerResult? {
        guard let poseDetector = poseDetector else { return nil }
        
        let mpImage = MPImage(uiImage: image)
        
        do {
            let result = try poseDetector.detect(image: mpImage)
            return result
        } catch {
            print("姿势检测失败: \(error)")
            return nil
        }
    }
}
```

### 康复动作评估
```swift
extension PoseDetectionService {
    
    // 评估手臂抬举角度
    func evaluateArmRaise(landmarks: [NormalizedLandmark]) -> Double {
        let shoulder = landmarks[11] // LEFT_SHOULDER
        let elbow = landmarks[13]    // LEFT_ELBOW
        let wrist = landmarks[15]    // LEFT_WRIST
        
        // 计算肩膀到肘部的角度
        let angle = calculateAngle(p1: shoulder, p2: elbow, p3: wrist)
        return angle
    }
    
    // 评估膝关节弯曲
    func evaluateKneeBend(landmarks: [NormalizedLandmark]) -> Double {
        let hip = landmarks[23]    // LEFT_HIP
        let knee = landmarks[25]   // LEFT_KNEE  
        let ankle = landmarks[27]  // LEFT_ANKLE
        
        let angle = calculateAngle(p1: hip, p2: knee, p3: ankle)
        return angle
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
```

## 性能参数
- **推理速度**: ~30-60ms (iPhone 12 Pro)
- **内存使用**: ~50-80MB
- **检测精度**: 95%+ (正常光照条件)
- **最大检测距离**: 3-4米
- **最佳检测角度**: 正面或侧面

## 注意事项
- 确保充足的光照条件
- 避免背景过于复杂
- 保持相机稳定
- 人体应完整出现在画面中
- 避免身体被遮挡 