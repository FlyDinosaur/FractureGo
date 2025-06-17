import Foundation
import Combine
import UIKit
import AVFoundation

// MARK: - 机器学习基础服务协议
protocol MLServiceProtocol {
    var isInitialized: Bool { get }
    func initialize() -> AnyPublisher<Bool, MLError>
    func cleanup()
}

// MARK: - 姿势检测服务协议
protocol PoseDetectionServiceProtocol: MLServiceProtocol {
    // 单张图片姿势检测
    func detectPose(in image: UIImage) -> AnyPublisher<PoseDetectionResult, MLError>
    
    // 实时视频流姿势检测
    func detectPose(in pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) -> AnyPublisher<PoseDetectionResult, MLError>
    
    // 配置检测参数
    func configure(confidence: Float, presenceThreshold: Float, trackingThreshold: Float)
    
    // 获取支持的姿势类型
    func getSupportedPoseTypes() -> [PoseType]
}

// MARK: - 手部检测服务协议
protocol HandDetectionServiceProtocol: MLServiceProtocol {
    // 单张图片手部检测
    func detectHands(in image: UIImage) -> AnyPublisher<HandDetectionResult, MLError>
    
    // 实时视频流手部检测
    func detectHands(in pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) -> AnyPublisher<HandDetectionResult, MLError>
    
    // 配置检测参数
    func configure(maxHands: Int, confidence: Float, presenceThreshold: Float, trackingThreshold: Float)
    
    // 获取支持的手势类型
    func getSupportedGestureTypes() -> [GestureType]
}

// MARK: - 康复评估服务协议
protocol RehabilitationAssessmentServiceProtocol {
    // 姿势评估
    func assessPosture(_ poseResult: PoseDetectionResult, exerciseType: ExerciseType) -> AnyPublisher<PostureAssessment, MLError>
    
    // 手部功能评估
    func assessHandFunction(_ handResult: HandDetectionResult, exerciseType: HandExerciseType) -> AnyPublisher<HandFunctionAssessment, MLError>
    
    // 运动轨迹分析
    func analyzeMovementTrajectory(_ trajectoryData: [LandmarkPoint], targetTrajectory: MovementPattern) -> AnyPublisher<TrajectoryAnalysis, MLError>
    
    // 获取康复建议
    func getRehabilitationRecommendations(_ assessments: [AssessmentResult]) -> AnyPublisher<[RehabilitationRecommendation], MLError>
}

// MARK: - 实时分析服务协议
protocol RealTimeAnalysisServiceProtocol {
    // 开始实时分析
    func startRealTimeAnalysis(exerciseType: ExerciseType) -> AnyPublisher<Void, MLError>
    
    // 停止实时分析
    func stopRealTimeAnalysis() -> AnyPublisher<Void, MLError>
    
    // 实时反馈流
    var realTimeFeedback: AnyPublisher<RealTimeFeedback, Never> { get }
    
    // 设置反馈回调
    func setFeedbackHandler(_ handler: @escaping (RealTimeFeedback) -> Void)
}

// MARK: - 数据模型协议

// 姿势检测结果
struct PoseDetectionResult {
    let landmarks: [LandmarkPoint]
    let confidence: Float
    let timestamp: TimeInterval
    let poseType: PoseType?
    let isVisible: Bool
}

// 手部检测结果
struct HandDetectionResult {
    let leftHand: HandLandmarks?
    let rightHand: HandLandmarks?
    let timestamp: TimeInterval
    let gestureType: GestureType?
}

// 手部关键点
struct HandLandmarks {
    let landmarks: [LandmarkPoint]
    let confidence: Float
    let handedness: Handedness
    let isVisible: Bool
}

// 关键点坐标
struct LandmarkPoint {
    let x: Float
    let y: Float
    let z: Float?
    let visibility: Float?
    let presence: Float?
}

// 姿势评估结果
struct PostureAssessment {
    let exerciseType: ExerciseType
    let accuracy: Float // 0.0-1.0
    let completionPercentage: Float // 0.0-1.0
    let jointAngles: [JointAngle]
    let symmetryScore: Float // 0.0-1.0
    let stabilityScore: Float // 0.0-1.0
    let recommendations: [String]
    let timestamp: TimeInterval
}

// 手部功能评估结果
struct HandFunctionAssessment {
    let exerciseType: HandExerciseType
    let accuracy: Float
    let rangeOfMotion: [FingerROM]
    let gripStrength: GripStrengthLevel
    let coordinationScore: Float
    let recommendations: [String]
    let timestamp: TimeInterval
}

// 轨迹分析结果
struct TrajectoryAnalysis {
    let accuracy: Float
    let smoothness: Float
    let speed: Float
    let deviation: Float
    let completionTime: TimeInterval
    let keyPoints: [TrajectoryKeyPoint]
}

// 实时反馈
struct RealTimeFeedback {
    let feedbackType: FeedbackType
    let message: String
    let accuracy: Float
    let suggestions: [String]
    let visualCues: [VisualCue]
    let audioFeedback: AudioFeedback?
}

// 关节角度
struct JointAngle {
    let jointType: JointType
    let angle: Float
    let normalRange: ClosedRange<Float>
    let isInNormalRange: Bool
}

// 手指活动范围
struct FingerROM {
    let finger: FingerType
    let flexionAngle: Float
    let extensionAngle: Float
    let normalFlexionRange: ClosedRange<Float>
    let normalExtensionRange: ClosedRange<Float>
}

// 轨迹关键点
struct TrajectoryKeyPoint {
    let position: LandmarkPoint
    let timestamp: TimeInterval
    let velocity: Float
    let acceleration: Float
}

// 视觉提示
struct VisualCue {
    let type: VisualCueType
    let position: CGPoint
    let color: UIColor
    let message: String
}

// 音频反馈
struct AudioFeedback {
    let type: AudioFeedbackType
    let volume: Float
    let message: String?
}

// MARK: - 枚举定义

enum PoseType: String, CaseIterable {
    case standing = "standing"
    case sitting = "sitting"
    case armRaise = "arm_raise"
    case shoulderStretch = "shoulder_stretch"
    case legLift = "leg_lift"
    case balance = "balance"
}

enum GestureType: String, CaseIterable {
    case openHand = "open_hand"
    case closedFist = "closed_fist"
    case pinchGrip = "pinch_grip"
    case thumbUp = "thumb_up"
    case pointing = "pointing"
    case peace = "peace"
}

enum ExerciseType: String, CaseIterable {
    case armRaise = "arm_raise"
    case shoulderRotation = "shoulder_rotation"
    case elbowFlexion = "elbow_flexion"
    case legRaise = "leg_raise"
    case kneeFlexion = "knee_flexion"
    case ankleFlexion = "ankle_flexion"
    case balanceTraining = "balance_training"
}

enum HandExerciseType: String, CaseIterable {
    case fingerFlexion = "finger_flexion"
    case fingerExtension = "finger_extension"
    case thumbOpposition = "thumb_opposition"
    case gripStrength = "grip_strength"
    case fingerIndependence = "finger_independence"
    case handCoordination = "hand_coordination"
}

enum Handedness: String {
    case left = "left"
    case right = "right"
}

enum JointType: String, CaseIterable {
    case shoulder = "shoulder"
    case elbow = "elbow"
    case wrist = "wrist"
    case hip = "hip"
    case knee = "knee"
    case ankle = "ankle"
}

enum FingerType: String, CaseIterable {
    case thumb = "thumb"
    case index = "index" 
    case middle = "middle"
    case ring = "ring"
    case pinky = "pinky"
}

enum GripStrengthLevel: String, CaseIterable {
    case weak = "weak"
    case fair = "fair"
    case good = "good"
    case excellent = "excellent"
}

enum FeedbackType: String {
    case positive = "positive"
    case corrective = "corrective"
    case warning = "warning"
    case completion = "completion"
}

enum VisualCueType: String {
    case arrow = "arrow"
    case circle = "circle"
    case line = "line"
    case text = "text"
}

enum AudioFeedbackType: String {
    case encouragement = "encouragement"
    case correction = "correction"
    case completion = "completion"
    case warning = "warning"
}

enum MovementPattern: String, CaseIterable {
    case linear = "linear"
    case circular = "circular"
    case zigzag = "zigzag"
    case custom = "custom"
}

// MARK: - 错误定义
enum MLError: Error, LocalizedError {
    case modelNotFound
    case modelInitializationFailed
    case imageProcessingFailed
    case detectionFailed(String)
    case invalidInput
    case resourceNotAvailable
    case cameraPermissionDenied
    case insufficientData
    case calibrationRequired
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "机器学习模型文件未找到"
        case .modelInitializationFailed:
            return "模型初始化失败"
        case .imageProcessingFailed:
            return "图像处理失败"
        case .detectionFailed(let message):
            return "检测失败: \(message)"
        case .invalidInput:
            return "输入数据无效"
        case .resourceNotAvailable:
            return "资源不可用"
        case .cameraPermissionDenied:
            return "相机权限被拒绝"
        case .insufficientData:
            return "数据不足"
        case .calibrationRequired:
            return "需要校准"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
}

// MARK: - 辅助协议
protocol AssessmentResult {
    var accuracy: Float { get }
    var timestamp: TimeInterval { get }
    var recommendations: [String] { get }
}

extension PostureAssessment: AssessmentResult {}
extension HandFunctionAssessment: AssessmentResult {}

// 康复建议
struct RehabilitationRecommendation {
    let type: RecommendationType
    let title: String
    let description: String
    let priority: Priority
    let targetArea: TargetArea
    let exercises: [String]
}

enum RecommendationType: String {
    case improvement = "improvement"
    case maintenance = "maintenance"
    case caution = "caution"
}

enum Priority: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

enum TargetArea: String {
    case mobility = "mobility"
    case strength = "strength"
    case coordination = "coordination"
    case balance = "balance"
} 