import Foundation
import Combine
import UIKit

// MARK: - 加密服务协议
protocol EncryptionServiceProtocol {
    func md5Hash(_ input: String) -> String
    func encrypt(_ data: String, key: String) -> String?
    func decrypt(_ encryptedData: String, key: String) -> String?
    func generateSalt() -> String
}

// MARK: - 验证服务协议
protocol ValidationServiceProtocol {
    func isValidPhoneNumber(_ phoneNumber: String) -> Bool
    func isValidPassword(_ password: String) -> Bool
    func isValidUsername(_ username: String) -> Bool
    func isValidEmail(_ email: String) -> Bool
    func getPasswordStrength(_ password: String) -> PasswordStrength
}

enum PasswordStrength: Int, CaseIterable {
    case weak = 1
    case medium = 2
    case strong = 3
    case veryStrong = 4
    
    var description: String {
        switch self {
        case .weak: return "弱"
        case .medium: return "中等"
        case .strong: return "强"
        case .veryStrong: return "很强"
        }
    }
    
    var color: UIColor {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .blue
        case .veryStrong: return .green
        }
    }
}

// MARK: - 网络服务协议
protocol NetworkServiceProtocol {
    func isNetworkAvailable() -> Bool
    func downloadImage(from url: String) -> AnyPublisher<UIImage?, NetworkError>
    func uploadImage(_ image: UIImage, to endpoint: String) -> AnyPublisher<String, NetworkError>
    func request<T: Codable>(_ endpoint: String, method: HTTPMethod, parameters: [String: Any]?) -> AnyPublisher<T, NetworkError>
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum NetworkError: Error, LocalizedError {
    case noConnection
    case invalidURL
    case timeout
    case serverError(Int)
    case decodingError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "网络连接不可用"
        case .invalidURL:
            return "无效的URL"
        case .timeout:
            return "请求超时"
        case .serverError(let code):
            return "服务器错误: \(code)"
        case .decodingError:
            return "数据解析错误"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - 文件管理服务协议
protocol FileManagerServiceProtocol {
    func saveImage(_ image: UIImage, to directory: String, filename: String) -> String?
    func loadImage(from path: String) -> UIImage?
    func deleteFile(at path: String) -> Bool
    func createDirectory(at path: String) -> Bool
    func getDocumentsDirectory() -> URL
    func getCacheDirectory() -> URL
    func getFileSize(at path: String) -> Int64?
    func clearCache() -> Bool
}

// MARK: - 通知服务协议
protocol NotificationServiceProtocol {
    func requestPermission() -> AnyPublisher<Bool, NotificationError>
    func scheduleNotification(title: String, body: String, date: Date, identifier: String) -> AnyPublisher<Bool, NotificationError>
    func cancelNotification(identifier: String)
    func cancelAllNotifications()
    func getPendingNotifications() -> AnyPublisher<[String], NotificationError>
}

enum NotificationError: Error, LocalizedError {
    case permissionDenied
    case invalidDate
    case schedulingFailed
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "通知权限被拒绝"
        case .invalidDate:
            return "无效的日期"
        case .schedulingFailed:
            return "通知调度失败"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - 缓存服务协议
protocol CacheServiceProtocol {
    func set<T: Codable>(_ object: T, forKey key: String)
    func get<T: Codable>(_ type: T.Type, forKey key: String) -> T?
    func remove(forKey key: String)
    func clearAll()
    func exists(forKey key: String) -> Bool
    func setExpiration(_ date: Date, forKey key: String)
    func isExpired(forKey key: String) -> Bool
}

// MARK: - 日志服务协议
protocol LoggingServiceProtocol {
    func log(_ message: String, level: LogLevel, category: LogCategory)
    func logError(_ error: Error, context: String?)
    func logUserAction(_ action: String, parameters: [String: Any]?)
    func exportLogs() -> URL?
    func clearLogs()
}

enum LogLevel: String, CaseIterable {
    case verbose = "VERBOSE"
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

enum LogCategory: String, CaseIterable {
    case authentication = "AUTH"
    case network = "NETWORK"
    case database = "DATABASE"
    case ui = "UI"
    case business = "BUSINESS"
    case system = "SYSTEM"
}

// MARK: - 分析服务协议
protocol AnalyticsServiceProtocol {
    func trackEvent(_ event: AnalyticsEvent, parameters: [String: Any]?)
    func trackScreen(_ screenName: String)
    func setUserProperty(_ property: String, value: String)
    func setUserID(_ userID: String)
    func logError(_ error: Error, context: String?)
}

enum AnalyticsEvent: String, CaseIterable {
    case appLaunch = "app_launch"
    case userLogin = "user_login"
    case userLogout = "user_logout"
    case userRegister = "user_register"
    case recoveryStart = "recovery_start"
    case levelComplete = "level_complete"
    case checkIn = "check_in"
    case forumPost = "forum_post"
    case settingsChange = "settings_change"
}

// MARK: - 设备信息服务协议
protocol DeviceInfoServiceProtocol {
    var deviceModel: String { get }
    var systemVersion: String { get }
    var appVersion: String { get }
    var buildNumber: String { get }
    var deviceID: String { get }
    var batteryLevel: Float { get }
    var isLowPowerModeEnabled: Bool { get }
    var availableStorage: Int64 { get }
    var totalStorage: Int64 { get }
}

// MARK: - 权限服务协议
protocol PermissionServiceProtocol {
    func requestCameraPermission() -> AnyPublisher<Bool, PermissionError>
    func requestPhotoLibraryPermission() -> AnyPublisher<Bool, PermissionError>
    func requestLocationPermission() -> AnyPublisher<Bool, PermissionError>
    func requestMicrophonePermission() -> AnyPublisher<Bool, PermissionError>
    func checkPermissionStatus(for permission: PermissionType) -> PermissionStatus
}

enum PermissionType {
    case camera
    case photoLibrary
    case location
    case microphone
    case notifications
}

enum PermissionStatus {
    case notDetermined
    case denied
    case authorized
    case restricted
}

enum PermissionError: Error, LocalizedError {
    case denied
    case restricted
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .denied:
            return "权限被拒绝"
        case .restricted:
            return "权限受限"
        case .unknown(let message):
            return message
        }
    }
} 