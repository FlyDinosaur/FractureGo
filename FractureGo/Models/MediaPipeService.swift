import Foundation
import Combine
import UIKit
import MediaPipeTasksVision

// MARK: - MediaPipe姿势检测服务
class MediaPipePoseDetectionService: PoseDetectionServiceProtocol {
    private(set) var isInitialized: Bool = false
    private var poseLandmarker: PoseLandmarker?
    
    func initialize() -> AnyPublisher<Bool, MLError> {
        return Future { [weak self] promise in
            do {
                // 获取模型文件路径
                guard let modelPath = self?.getModelPath(for: "pose_landmarker") else {
                    promise(.failure(.modelNotFound))
                    return
                }
                
                // 配置MediaPipe姿势检测器
                let options = PoseLandmarkerOptions()
                options.baseOptions.modelAssetPath = modelPath
                options.runningMode = .image
                options.minPoseDetectionConfidence = 0.5
                options.minPosePresenceConfidence = 0.5
                options.minTrackingConfidence = 0.5
                
                // 初始化姿势检测器
                self?.poseLandmarker = try PoseLandmarker(options: options)
                self?.isInitialized = true
                promise(.success(true))
                
            } catch {
                print("姿势检测器初始化失败: \(error.localizedDescription)")
                promise(.failure(.modelInitializationFailed))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func getModelPath(for modelName: String) -> String? {
        // 首先尝试从Bundle中获取
        if let bundlePath = Bundle.main.path(forResource: modelName, ofType: "task") {
            return bundlePath
        }
        
        // 如果Bundle中没有，尝试从MLModels目录获取
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let mlModelsPath = documentsPath.replacingOccurrences(of: "/Documents", with: "")
        
        let possiblePaths = [
            "\(mlModelsPath)/MLModels/PoseDetection/\(modelName).task",
            "./MLModels/PoseDetection/\(modelName).task",
            "\(FileManager.default.currentDirectoryPath)/MLModels/PoseDetection/\(modelName).task"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        return nil
    }
    
    func detectPose(in image: UIImage) -> AnyPublisher<PoseDetectionResult, MLError> {
        return Future { [weak self] promise in
            guard let self = self, self.isInitialized, let poseLandmarker = self.poseLandmarker else {
                promise(.failure(.modelNotFound))
                return
            }
            
            do {
                // 将UIImage转换为MPImage
                let mpImage = try MPImage(uiImage: image)
                
                // 执行姿势检测
                let result = try poseLandmarker.detect(image: mpImage)
                
                // 转换结果
                if let poseLandmarks = result.landmarks.first {
                    let landmarks = poseLandmarks.map { landmark in
                        LandmarkPoint(
                            x: landmark.x,
                            y: landmark.y,
                            z: landmark.z,
                            visibility: landmark.visibility?.floatValue,
                            presence: landmark.presence?.floatValue
                        )
                    }
                    
                    let poseResult = PoseDetectionResult(
                        landmarks: landmarks,
                        confidence: 0.8, // MediaPipe doesn't provide overall confidence
                        timestamp: Date().timeIntervalSince1970,
                        poseType: self.determinePoseType(from: landmarks),
                        isVisible: true
                    )
                    
                    promise(.success(poseResult))
                } else {
                    // 没有检测到姿势
                    let emptyResult = PoseDetectionResult(
                        landmarks: [],
                        confidence: 0.0,
                        timestamp: Date().timeIntervalSince1970,
                        poseType: nil,
                        isVisible: false
                    )
                    promise(.success(emptyResult))
                }
                
            } catch {
                print("姿势检测失败: \(error.localizedDescription)")
                promise(.failure(.detectionFailed(error.localizedDescription)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func determinePoseType(from landmarks: [LandmarkPoint]) -> PoseType? {
        // 简单的姿势分类逻辑
        // 这里可以根据关键点位置判断姿势类型
        guard landmarks.count >= 33 else { return nil }
        
        // 示例：通过鼻子、肩膀、臀部的相对位置判断站立或坐下
        let nose = landmarks[0]
        let leftShoulder = landmarks[11]
        let rightShoulder = landmarks[12]
        let leftHip = landmarks[23]
        let rightHip = landmarks[24]
        
        let shoulderMidpoint = (leftShoulder.y + rightShoulder.y) / 2
        let hipMidpoint = (leftHip.y + rightHip.y) / 2
        
        let torsoLength = abs(shoulderMidpoint - hipMidpoint)
        
        if torsoLength > 0.3 {
            return .standing
        } else {
            return .sitting
        }
    }
    
    func detectPose(in pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) -> AnyPublisher<PoseDetectionResult, MLError> {
        return Future { [weak self] promise in
            guard let self = self, self.isInitialized, let poseLandmarker = self.poseLandmarker else {
                promise(.failure(.modelNotFound))
                return
            }
            
            do {
                // 将CVPixelBuffer转换为MPImage
                let mpImage = try MPImage(pixelBuffer: pixelBuffer)
                
                // 执行姿势检测
                let result = try poseLandmarker.detect(image: mpImage)
                
                // 处理结果（与上面类似的逻辑）
                if let poseLandmarks = result.landmarks.first {
                    let landmarks = poseLandmarks.map { landmark in
                        LandmarkPoint(
                            x: landmark.x,
                            y: landmark.y,
                            z: landmark.z,
                            visibility: landmark.visibility?.floatValue,
                            presence: landmark.presence?.floatValue
                        )
                    }
                    
                    let poseResult = PoseDetectionResult(
                        landmarks: landmarks,
                        confidence: 0.8,
                        timestamp: timestamp,
                        poseType: self.determinePoseType(from: landmarks),
                        isVisible: true
                    )
                    
                    promise(.success(poseResult))
                } else {
                    let emptyResult = PoseDetectionResult(
                        landmarks: [],
                        confidence: 0.0,
                        timestamp: timestamp,
                        poseType: nil,
                        isVisible: false
                    )
                    promise(.success(emptyResult))
                }
                
            } catch {
                promise(.failure(.detectionFailed(error.localizedDescription)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func configure(confidence: Float, presenceThreshold: Float, trackingThreshold: Float) {
        // 重新配置检测器参数
        // 注意：MediaPipe的参数需要在初始化时设置，运行时修改需要重新初始化
    }
    
    func getSupportedPoseTypes() -> [PoseType] {
        return PoseType.allCases
    }
    
    func cleanup() {
        poseLandmarker = nil
        isInitialized = false
    }
}

// MARK: - MediaPipe手部检测服务
class MediaPipeHandDetectionService: HandDetectionServiceProtocol {
    private(set) var isInitialized: Bool = false
    private var handLandmarker: HandLandmarker?
    
    func initialize() -> AnyPublisher<Bool, MLError> {
        return Future { [weak self] promise in
            do {
                // 获取模型文件路径
                guard let modelPath = self?.getModelPath(for: "hand_landmarker") else {
                    promise(.failure(.modelNotFound))
                    return
                }
                
                // 配置MediaPipe手部检测器
                let options = HandLandmarkerOptions()
                options.baseOptions.modelAssetPath = modelPath
                options.runningMode = .image
                options.numHands = 2
                options.minHandDetectionConfidence = 0.5
                options.minHandPresenceConfidence = 0.5
                options.minTrackingConfidence = 0.5
                
                // 初始化手部检测器
                self?.handLandmarker = try HandLandmarker(options: options)
                self?.isInitialized = true
                promise(.success(true))
                
            } catch {
                print("手部检测器初始化失败: \(error.localizedDescription)")
                promise(.failure(.modelInitializationFailed))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func getModelPath(for modelName: String) -> String? {
        // 首先尝试从Bundle中获取
        if let bundlePath = Bundle.main.path(forResource: modelName, ofType: "task") {
            return bundlePath
        }
        
        // 如果Bundle中没有，尝试从MLModels目录获取
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let mlModelsPath = documentsPath.replacingOccurrences(of: "/Documents", with: "")
        
        let possiblePaths = [
            "\(mlModelsPath)/MLModels/HandDetection/\(modelName).task",
            "./MLModels/HandDetection/\(modelName).task",
            "\(FileManager.default.currentDirectoryPath)/MLModels/HandDetection/\(modelName).task"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        return nil
    }
    
    func detectHands(in image: UIImage) -> AnyPublisher<HandDetectionResult, MLError> {
        return Future { [weak self] promise in
            guard let self = self, self.isInitialized, let handLandmarker = self.handLandmarker else {
                promise(.failure(.modelNotFound))
                return
            }
            
            do {
                // 将UIImage转换为MPImage
                let mpImage = try MPImage(uiImage: image)
                
                // 执行手部检测
                let result = try handLandmarker.detect(image: mpImage)
                
                // 转换结果
                var leftHand: HandLandmarks? = nil
                var rightHand: HandLandmarks? = nil
                
                for (index, handLandmarks) in result.landmarks.enumerated() {
                    guard index < result.handedness.count else { continue }
                    
                    let landmarks = handLandmarks.map { landmark in
                        LandmarkPoint(
                            x: landmark.x,
                            y: landmark.y,
                            z: landmark.z,
                            visibility: nil,
                            presence: nil
                        )
                    }
                    
                    let handedness = result.handedness[index]
                    let isLeft = handedness.first?.categoryName == "Left"
                    
                    let handLandmarkResult = HandLandmarks(
                        landmarks: landmarks,
                        confidence: handedness.first?.score ?? 0.0,
                        handedness: isLeft ? .left : .right,
                        isVisible: true
                    )
                    
                    if isLeft {
                        leftHand = handLandmarkResult
                    } else {
                        rightHand = handLandmarkResult
                    }
                }
                
                let handResult = HandDetectionResult(
                    leftHand: leftHand,
                    rightHand: rightHand,
                    timestamp: Date().timeIntervalSince1970,
                    gestureType: self.determineGestureType(leftHand: leftHand, rightHand: rightHand)
                )
                
                promise(.success(handResult))
                
            } catch {
                print("手部检测失败: \(error.localizedDescription)")
                promise(.failure(.detectionFailed(error.localizedDescription)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func determineGestureType(leftHand: HandLandmarks?, rightHand: HandLandmarks?) -> GestureType? {
        // 简单的手势识别逻辑
        // 这里可以根据手部关键点位置判断手势类型
        guard let hand = leftHand ?? rightHand, hand.landmarks.count >= 21 else {
            return nil
        }
        
        // 示例：通过手指间的距离判断手势
        let landmarks = hand.landmarks
        let thumb_tip = landmarks[4]
        let index_tip = landmarks[8]
        let middle_tip = landmarks[12]
        let ring_tip = landmarks[16]
        let pinky_tip = landmarks[20]
        
        // 计算手指是否伸展
        let wrist = landmarks[0]
        let fingersExtended = [
            distance(thumb_tip, wrist) > 0.1,
            distance(index_tip, wrist) > 0.15,
            distance(middle_tip, wrist) > 0.15,
            distance(ring_tip, wrist) > 0.15,
            distance(pinky_tip, wrist) > 0.1
        ]
        
        let extendedCount = fingersExtended.filter { $0 }.count
        
        switch extendedCount {
        case 0, 1:
            return .closedFist
        case 5:
            return .openHand
        case 2:
            return .peace
        default:
            return .pointing
        }
    }
    
    private func distance(_ point1: LandmarkPoint, _ point2: LandmarkPoint) -> Float {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    func detectHands(in pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) -> AnyPublisher<HandDetectionResult, MLError> {
        return Future { [weak self] promise in
            guard let self = self, self.isInitialized, let handLandmarker = self.handLandmarker else {
                promise(.failure(.modelNotFound))
                return
            }
            
            do {
                // 将CVPixelBuffer转换为MPImage
                let mpImage = try MPImage(pixelBuffer: pixelBuffer)
                
                // 执行手部检测（与上面类似的逻辑）
                let result = try handLandmarker.detect(image: mpImage)
                
                var leftHand: HandLandmarks? = nil
                var rightHand: HandLandmarks? = nil
                
                for (index, handLandmarks) in result.landmarks.enumerated() {
                    guard index < result.handedness.count else { continue }
                    
                    let landmarks = handLandmarks.map { landmark in
                        LandmarkPoint(
                            x: landmark.x,
                            y: landmark.y,
                            z: landmark.z,
                            visibility: nil,
                            presence: nil
                        )
                    }
                    
                    let handedness = result.handedness[index]
                    let isLeft = handedness.first?.categoryName == "Left"
                    
                    let handLandmarkResult = HandLandmarks(
                        landmarks: landmarks,
                        confidence: handedness.first?.score ?? 0.0,
                        handedness: isLeft ? .left : .right,
                        isVisible: true
                    )
                    
                    if isLeft {
                        leftHand = handLandmarkResult
                    } else {
                        rightHand = handLandmarkResult
                    }
                }
                
                let handResult = HandDetectionResult(
                    leftHand: leftHand,
                    rightHand: rightHand,
                    timestamp: timestamp,
                    gestureType: self.determineGestureType(leftHand: leftHand, rightHand: rightHand)
                )
                
                promise(.success(handResult))
                
            } catch {
                promise(.failure(.detectionFailed(error.localizedDescription)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func configure(maxHands: Int, confidence: Float, presenceThreshold: Float, trackingThreshold: Float) {
        // 重新配置检测器参数
        // 注意：MediaPipe的参数需要在初始化时设置，运行时修改需要重新初始化
    }
    
    func getSupportedGestureTypes() -> [GestureType] {
        return GestureType.allCases
    }
    
    func cleanup() {
        handLandmarker = nil
        isInitialized = false
    }
}

// MARK: - ML服务管理器
class MLServiceManager {
    static let shared = MLServiceManager()
    
    let poseDetectionService: PoseDetectionServiceProtocol
    let handDetectionService: HandDetectionServiceProtocol
    
    private init() {
        self.poseDetectionService = MediaPipePoseDetectionService()
        self.handDetectionService = MediaPipeHandDetectionService()
    }
    
    func initializeAllServices() -> AnyPublisher<Bool, MLError> {
        let poseInit = poseDetectionService.initialize()
        let handInit = handDetectionService.initialize()
        
        return Publishers.Zip(poseInit, handInit)
            .map { $0.0 && $0.1 }
            .eraseToAnyPublisher()
    }
    
    func cleanupAllServices() {
        poseDetectionService.cleanup()
        handDetectionService.cleanup()
    }
}