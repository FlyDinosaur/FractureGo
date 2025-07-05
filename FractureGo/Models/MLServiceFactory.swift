import Foundation
import Combine

// MARK: - ML服务工厂
class MLServiceFactory {
    static let shared = MLServiceFactory()
    
    private init() {}
    
    // MARK: - 姿势检测服务
    func createPoseDetectionService() -> PoseDetectionServiceProtocol {
        return MediaPipePoseDetectionService()
    }
    
    // MARK: - 手部检测服务
    func createHandDetectionService() -> HandDetectionServiceProtocol {
        return MediaPipeHandDetectionService()
    }
}