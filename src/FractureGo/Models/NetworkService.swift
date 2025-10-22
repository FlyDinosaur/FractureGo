//
//  NetworkService.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import Foundation
import Combine

/// 网络服务类，处理所有API调用
class NetworkService: ObservableObject {
    static let shared = NetworkService()
    
    private let databaseConfig = DatabaseConfig.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - 用户认证API
    
    /// 用户注册
    func register(
        phoneNumber: String,
        password: String,
        nickname: String,
        userType: String,
        birthDate: Date,
        isWeChatUser: Bool = false,
        wechatOpenId: String? = nil,
        wechatUnionId: String? = nil,
        wechatNickname: String? = nil,
        wechatAvatarUrl: String? = nil,
        completion: @escaping (Result<UserAuthResponse, NetworkError>) -> Void
    ) {
        guard var request = databaseConfig.createURLRequest(for: "/auth/register", method: .POST) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        let requestBody = RegisterRequest(
            phoneNumber: phoneNumber,
            password: password,
            nickname: nickname,
            userType: userType,
            birthDate: ISO8601DateFormatter().string(from: birthDate),
            isWeChatUser: isWeChatUser,
            wechatOpenId: wechatOpenId,
            wechatUnionId: wechatUnionId,
            wechatNickname: wechatNickname,
            wechatAvatarUrl: wechatAvatarUrl
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(.decodingError("请求数据编码失败")))
            return
        }
        
        databaseConfig.executeRequest(request: request, responseType: APIResponse<UserAuthResponse>.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success, let data = response.data {
                        // 存储Token
                        self.databaseConfig.storeToken(data.token)
                        completion(.success(data))
                    } else {
                        completion(.failure(.requestFailed(response.message ?? "注册失败")))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 用户登录
    func login(
        phoneNumber: String,
        password: String,
        completion: @escaping (Result<UserAuthResponse, NetworkError>) -> Void
    ) {
        guard var request = databaseConfig.createURLRequest(for: "/auth/login", method: .POST) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        let requestBody = LoginRequest(phoneNumber: phoneNumber, password: password)
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(.decodingError("请求数据编码失败")))
            return
        }
        
        databaseConfig.executeRequest(request: request, responseType: APIResponse<UserAuthResponse>.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success, let data = response.data {
                        // 存储Token
                        self.databaseConfig.storeToken(data.token)
                        completion(.success(data))
                    } else {
                        completion(.failure(.requestFailed(response.message ?? "登录失败")))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 微信登录
    func wechatLogin(
        openId: String,
        unionId: String?,
        nickname: String,
        avatarUrl: String?,
        completion: @escaping (Result<UserAuthResponse, NetworkError>) -> Void
    ) {
        guard var request = databaseConfig.createURLRequest(for: "/auth/wechat-login", method: .POST) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        let requestBody = WeChatLoginRequest(
            openId: openId,
            unionId: unionId,
            nickname: nickname,
            avatarUrl: avatarUrl
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(.decodingError("请求数据编码失败")))
            return
        }
        
        databaseConfig.executeRequest(request: request, responseType: APIResponse<UserAuthResponse>.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success, let data = response.data {
                        // 存储Token
                        self.databaseConfig.storeToken(data.token)
                        completion(.success(data))
                    } else {
                        completion(.failure(.requestFailed(response.message ?? "微信登录失败")))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - 用户信息API
    
    /// 获取用户信息
    func getUserProfile(completion: @escaping (Result<User, NetworkError>) -> Void) {
        guard var request = databaseConfig.createURLRequest(for: "/user/profile", method: .GET) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        databaseConfig.addAuthToken(to: &request)
        
        databaseConfig.executeRequest(request: request, responseType: APIResponse<UserProfileResponse>.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success, let data = response.data {
                        completion(.success(data.user))
                    } else {
                        completion(.failure(.requestFailed(response.message ?? "获取用户信息失败")))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 更新用户信息
    func updateUserProfile(
        nickname: String,
        birthDate: Date,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        guard var request = databaseConfig.createURLRequest(for: "/user/profile", method: .PUT) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        databaseConfig.addAuthToken(to: &request)
        
        let requestBody = UpdateProfileRequest(
            nickname: nickname,
            birthDate: ISO8601DateFormatter().string(from: birthDate)
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(.decodingError("请求数据编码失败")))
            return
        }
        
        databaseConfig.executeRequest(request: request, responseType: APIResponse<EmptyResponse>.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        completion(.success(()))
                    } else {
                        completion(.failure(.requestFailed(response.message ?? "更新用户信息失败")))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - 训练相关API
    
    /// 获取训练进度
    func getTrainingProgress(
        trainingType: String? = nil,
        completion: @escaping (Result<[TrainingProgress], NetworkError>) -> Void
    ) {
        var endpoint = "/training/progress"
        if let trainingType = trainingType {
            endpoint += "?trainingType=\(trainingType)"
        }
        
        guard var request = databaseConfig.createURLRequest(for: endpoint, method: .GET) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        databaseConfig.addAuthToken(to: &request)
        
        databaseConfig.executeRequest(request: request, responseType: APIResponse<TrainingProgressResponse>.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success, let data = response.data {
                        completion(.success(data.progress))
                    } else {
                        completion(.failure(.requestFailed(response.message ?? "获取训练进度失败")))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 记录训练成绩
    func recordTraining(
        trainingType: String,
        level: Int,
        score: Int,
        duration: Int,
        data: [String: Any]? = nil,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        guard var request = databaseConfig.createURLRequest(for: "/training/record", method: .POST) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        databaseConfig.addAuthToken(to: &request)
        
        let requestBody = RecordTrainingRequest(
            trainingType: trainingType,
            level: level,
            score: score,
            duration: duration,
            data: data
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(.decodingError("请求数据编码失败")))
            return
        }
        
        databaseConfig.executeRequest(request: request, responseType: APIResponse<EmptyResponse>.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        completion(.success(()))
                    } else {
                        completion(.failure(.requestFailed(response.message ?? "记录训练成绩失败")))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 获取训练历史
    func getTrainingHistory(
        trainingType: String? = nil,
        page: Int = 1,
        limit: Int = 20,
        completion: @escaping (Result<TrainingHistoryResponse, NetworkError>) -> Void
    ) {
        var endpoint = "/training/history?page=\(page)&limit=\(limit)"
        if let trainingType = trainingType {
            endpoint += "&trainingType=\(trainingType)"
        }
        
        guard var request = databaseConfig.createURLRequest(for: endpoint, method: .GET) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        databaseConfig.addAuthToken(to: &request)
        
        databaseConfig.executeRequest(request: request, responseType: APIResponse<TrainingHistoryResponse>.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success, let data = response.data {
                        completion(.success(data))
                    } else {
                        completion(.failure(.requestFailed(response.message ?? "获取训练历史失败")))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - 签到相关API
    
    /// 获取签到统计数据
    func getSignInStats(completion: @escaping (Result<SignInStatsResponse, NetworkError>) -> Void) {
        guard var request = databaseConfig.createURLRequest(for: "/signin/stats", method: .GET) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        databaseConfig.addAuthToken(to: &request)
        
        databaseConfig.executeRequest(request: request, responseType: APIResponse<SignInStatsResponse>.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success, let data = response.data {
                        completion(.success(data))
                    } else {
                        completion(.failure(.requestFailed(response.message ?? "获取签到统计失败")))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 获取指定月份签到数据
    func getSignInData(year: Int, month: Int, completion: @escaping (Result<SignInDataResponse, NetworkError>) -> Void) {
        let endpoint = "/signin/month?year=\(year)&month=\(month)"
        guard var request = databaseConfig.createURLRequest(for: endpoint, method: .GET) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        databaseConfig.addAuthToken(to: &request)
        
        databaseConfig.executeRequest(request: request, responseType: APIResponse<SignInDataResponse>.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success, let data = response.data {
                        completion(.success(data))
                    } else {
                        completion(.failure(.requestFailed(response.message ?? "获取签到数据失败")))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 执行签到
    func signIn(completion: @escaping (Result<SignInResponse, NetworkError>) -> Void) {
        guard var request = databaseConfig.createURLRequest(for: "/signin", method: .POST) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        databaseConfig.addAuthToken(to: &request)
        
        databaseConfig.executeRequest(request: request, responseType: APIResponse<SignInResponse>.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success, let data = response.data {
                        completion(.success(data))
                    } else {
                        completion(.failure(.requestFailed(response.message ?? "签到失败")))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 更新当前关卡
    func updateCurrentLevel(
        trainingType: String,
        level: Int,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        guard var request = databaseConfig.createURLRequest(for: "/training/current-level", method: .PUT) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        databaseConfig.addAuthToken(to: &request)
        
        let requestBody = UpdateCurrentLevelRequest(trainingType: trainingType, level: level)
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } catch {
            completion(.failure(.invalidResponse))
            return
        }
        
        databaseConfig.executeRequest(request: request, responseType: APIResponse<EmptyResponse>.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        completion(.success(()))
                    } else {
                        completion(.failure(.requestFailed(response.message ?? "更新关卡失败")))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - 健康检查
    func checkServerHealth(completion: @escaping (Bool) -> Void) {
        databaseConfig.healthCheck { success, _ in
            completion(success)
        }
    }
    
    // MARK: - 登出
    func logout() {
        databaseConfig.clearToken()
    }
}

// MARK: - 请求模型

struct RegisterRequest: Codable {
    let phoneNumber: String
    let password: String
    let nickname: String
    let userType: String
    let birthDate: String
    let isWeChatUser: Bool
    let wechatOpenId: String?
    let wechatUnionId: String?
    let wechatNickname: String?
    let wechatAvatarUrl: String?
}

struct LoginRequest: Codable {
    let phoneNumber: String
    let password: String
}

struct WeChatLoginRequest: Codable {
    let openId: String
    let unionId: String?
    let nickname: String
    let avatarUrl: String?
}

struct UpdateProfileRequest: Codable {
    let nickname: String
    let birthDate: String
}

struct RecordTrainingRequest: Codable {
    let trainingType: String
    let level: Int
    let score: Int
    let duration: Int
    let data: String?
    
    init(trainingType: String, level: Int, score: Int, duration: Int, data: [String: Any]? = nil) {
        self.trainingType = trainingType
        self.level = level
        self.score = score
        self.duration = duration
        
        if let data = data {
            let jsonData = try? JSONSerialization.data(withJSONObject: data)
            self.data = jsonData?.base64EncodedString()
        } else {
            self.data = nil
        }
    }
}

struct UpdateCurrentLevelRequest: Codable {
    let trainingType: String
    let level: Int
}

// MARK: - 响应模型

struct UserAuthResponse: Codable {
    let user: User
    let token: String
}

struct User: Codable {
    let id: Int
    let phoneNumber: String
    let nickname: String
    let userType: String
    let birthDate: String
    let isWeChatUser: Bool
    let wechatNickname: String?
    let wechatAvatarUrl: String?
    
    // 自定义解码器来处理isWeChatUser字段的类型转换
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        nickname = try container.decode(String.self, forKey: .nickname)
        userType = try container.decode(String.self, forKey: .userType)
        birthDate = try container.decode(String.self, forKey: .birthDate)
        wechatNickname = try container.decodeIfPresent(String.self, forKey: .wechatNickname)
        wechatAvatarUrl = try container.decodeIfPresent(String.self, forKey: .wechatAvatarUrl)
        
        // 处理isWeChatUser字段，支持Bool和数字类型
        if let boolValue = try? container.decode(Bool.self, forKey: .isWeChatUser) {
            isWeChatUser = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isWeChatUser) {
            isWeChatUser = intValue != 0
        } else {
            isWeChatUser = false // 默认值
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, phoneNumber, nickname, userType, birthDate, isWeChatUser, wechatNickname, wechatAvatarUrl
    }
}

struct UserProfileResponse: Codable {
    let user: User
}

struct TrainingProgress: Codable {
    let id: Int
    let trainingType: String
    let currentLevel: Int
    let maxLevelReached: Int
    let totalTrainingTime: Int
    let totalSessions: Int
    let bestScore: Int
}

struct TrainingProgressResponse: Codable {
    let progress: [TrainingProgress]
}

struct TrainingRecord: Codable {
    let id: Int
    let trainingType: String
    let level: Int
    let score: Int
    let duration: Int
    let completedAt: String
    let data: String?
    
    var decodedData: [String: Any]? {
        guard let data = data,
              let jsonData = Data(base64Encoded: data),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }
        return jsonObject
    }
}

struct TrainingHistoryResponse: Codable {
    let records: [TrainingRecord]
    let pagination: PaginationInfo
}

struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}

struct EmptyResponse: Codable {}

// MARK: - 签到相关响应模型

struct SignInStatsResponse: Codable {
    let totalDays: Int
    let currentStreak: Int
    let longestStreak: Int
    let totalRewards: Int
}

struct SignInDataResponse: Codable {
    let year: Int
    let month: Int
    let signIns: [SignInRecord]
}

struct SignInRecord: Codable {
    let id: Int
    let day: Int
    let signInType: String  // "normal", "gift", "target"
    let rewardPoints: Int
    let signedAt: String
}

struct SignInResponse: Codable {
    let signInId: Int
    let day: Int
    let signInType: String
    let rewardPoints: Int
    let currentStreak: Int
    let totalRewards: Int
    let message: String
}

 