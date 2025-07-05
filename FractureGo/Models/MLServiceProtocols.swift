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
    func detectPose(in image: UIImage) -> AnyPublisher<PoseDetectionResult, MLError>
    func detectPose(in pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) -> AnyPublisher<PoseDetectionResult, MLError>
    func configure(confidence: Float, presenceThreshold: Float, trackingThreshold: Float)
    func getSupportedPoseTypes() -> [PoseType]
}

// MARK: - 手部检测服务协议
protocol HandDetectionServiceProtocol: MLServiceProtocol {
    func detectHands(in image: UIImage) -> AnyPublisher<HandDetectionResult, MLError>
    func detectHands(in pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) -> AnyPublisher<HandDetectionResult, MLError>
    func configure(maxHands: Int, confidence: Float, presenceThreshold: Float, trackingThreshold: Float)
    func getSupportedGestureTypes() -> [GestureType]
}

// MARK: - 康复评估服务协议
protocol RehabilitationAssessmentServiceProtocol: MLServiceProtocol {
    func assessMovement(_ movement: MovementData) -> AnyPublisher<AssessmentResult, MLError>
    func getExerciseProgress(for exerciseType: ExerciseType, timeRange: TimeInterval) -> AnyPublisher<[ProgressData], MLError>
    func generateReport(for timeRange: TimeInterval) -> AnyPublisher<RehabilitationReport, MLError>
}

// MARK: - 实时分析服务协议
protocol RealTimeAnalysisServiceProtocol: MLServiceProtocol {
    var isAnalyzing: Bool { get }
    func startAnalysis() -> AnyPublisher<AnalysisResult, MLError>
    func stopAnalysis()
    func processFrame(_ frameData: FrameData) -> AnyPublisher<AnalysisResult, MLError>
    func configure(analysisFrequency: Double, confidenceThreshold: Float)
}

// MARK: - 数据模型

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

// 评估结果
struct AssessmentResult {
    let score: Float
    let feedback: String
    let recommendations: [String]
    let timestamp: TimeInterval
    let exerciseType: ExerciseType
    let completionRate: Float
}

// 进度数据
struct ProgressData {
    let date: Date
    let score: Float
    let exerciseType: ExerciseType
    let duration: TimeInterval
    let repetitions: Int
}

// 康复报告
struct RehabilitationReport {
    let startDate: Date
    let endDate: Date
    let overallScore: Float
    let exercisesSummary: [ExerciseType: Float]
    let recommendations: [String]
    let progressTrend: ProgressTrend
}

// 分析结果
struct AnalysisResult {
    let timestamp: TimeInterval
    let analysisType: AnalysisType
    let confidence: Float
    let data: [String: Any]
    let recommendations: [String]
}

// 帧数据
struct FrameData {
    let timestamp: TimeInterval
    let pixelBuffer: CVPixelBuffer?
    let image: UIImage?
}

// 运动数据
struct MovementData {
    let exerciseType: ExerciseType
    let poseResults: [PoseDetectionResult]
    let handResults: [HandDetectionResult]
    let duration: TimeInterval
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

enum Handedness: String {
    case left = "left"
    case right = "right"
}

enum ProgressTrend: String {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
}

enum AnalysisType: String {
    case movement = "movement"
    case posture = "posture"
    case gesture = "gesture"
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