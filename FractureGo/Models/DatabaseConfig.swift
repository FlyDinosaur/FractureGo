//
//  DatabaseConfig.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import Foundation
import Network

/// 数据库连接配置管理器
class DatabaseConfig: ObservableObject {
    static let shared = DatabaseConfig()
    
    // MARK: - 服务器配置
    private let baseURL: String
    private let port: Int
    private let apiKey: String
    private let timeout: TimeInterval
    private let maxRetries: Int
    
    // MARK: - 网络监控
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    @Published var isConnected = true
    
    // MARK: - 安全配置
    private let allowedHosts: Set<String>
    private let certificatePinning: Bool
    
    // MARK: - 初始化
    private init() {
        // 从配置文件或环境变量读取配置
        #if DEBUG
        // 开发环境配置 - 连接到远程服务器进行测试
        self.baseURL = "http://117.72.161.6"
        self.port = 28974
        self.apiKey = "ak_aa0151d02fa4ff2ff657409a1908e0a4"
        #else
        // 生产环境配置 - 同样连接到远程服务器
        self.baseURL = "http://117.72.161.6"
        self.port = 28974
        self.apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String ?? "ak_aa0151d02fa4ff2ff657409a1908e0a4"
        #endif
        
        self.timeout = 30.0
        self.maxRetries = 3
        
        // 安全配置
        self.allowedHosts = [
            "localhost",
            "127.0.0.1",
            "117.72.161.6"
        ]
        self.certificatePinning = true
        
        setupNetworkMonitoring()
    }
    
    // MARK: - 网络监控
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    // MARK: - 公共属性
    var fullBaseURL: String {
        return "\(baseURL):\(port)"
    }
    
    var apiBaseURL: String {
        return "\(fullBaseURL)/api/v1"
    }
    
    var healthCheckURL: String {
        return "\(fullBaseURL)/health"
    }
    
    // MARK: - 请求配置
    func createURLRequest(for endpoint: String, method: HTTPMethod = .GET) -> URLRequest? {
        guard let url = URL(string: "\(apiBaseURL)\(endpoint)") else {
            print("❌ 无效的URL: \(apiBaseURL)\(endpoint)")
            return nil
        }
        
        // 验证主机安全性
        guard let host = url.host, allowedHosts.contains(host) else {
            print("❌ 不被信任的主机: \(url.host ?? "unknown")")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeout
        
        // 设置通用请求头
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("FractureGo-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        return request
    }
    
    // MARK: - JWT Token管理
    func addAuthToken(to request: inout URLRequest) {
        if let token = getStoredToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    private func getStoredToken() -> String? {
        return UserDefaults.standard.string(forKey: "auth_token")
    }
    
    func storeToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "auth_token")
    }
    
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    // MARK: - 网络请求执行
    func executeRequest<T: Codable>(
        request: URLRequest,
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        // 检查网络连接
        guard isConnected else {
            completion(.failure(.noConnection))
            return
        }
        
        executeRequestWithRetry(request: request, responseType: responseType, retryCount: 0, completion: completion)
    }
    
    private func executeRequestWithRetry<T: Codable>(
        request: URLRequest,
        responseType: T.Type,
        retryCount: Int,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // 处理网络错误
            if let error = error {
                if retryCount < self.maxRetries {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(retryCount + 1)) {
                        self.executeRequestWithRetry(
                            request: request,
                            responseType: responseType,
                            retryCount: retryCount + 1,
                            completion: completion
                        )
                    }
                    return
                }
                
                completion(.failure(.requestFailed(error.localizedDescription)))
                return
            }
            
            // 检查HTTP状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            // 处理特殊状态码
            switch httpResponse.statusCode {
            case 401:
                // Token过期，清除本地存储
                DispatchQueue.main.async {
                    self.clearToken()
                }
                completion(.failure(.unauthorized))
                return
            case 403:
                completion(.failure(.forbidden))
                return
            case 429:
                completion(.failure(.rateLimited))
                return
            case 500...599:
                completion(.failure(.serverError))
                return
            case 200...299:
                // 成功状态码，继续处理
                break
            default:
                // 其他状态码视为客户端错误
                completion(.failure(.requestFailed("HTTP状态码: \(httpResponse.statusCode)")))
                return
            }
            
            // 解析响应数据
            guard let data = data else {
                completion(.failure(.invalidData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let result = try decoder.decode(responseType, from: data)
                completion(.success(result))
            } catch {
                print("❌ JSON解析错误: \(error)")
                completion(.failure(.decodingError(error.localizedDescription)))
            }
        }.resume()
    }
    
    // MARK: - 健康检查
    func healthCheck(completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: healthCheckURL) else {
            completion(false, "无效的健康检查URL")
            return
        }
        
        // 验证主机安全性
        guard let host = url.host, allowedHosts.contains(host) else {
            completion(false, "不被信任的主机: \(url.host ?? "unknown")")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        
        // 添加必要的请求头
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("FractureGo-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, "连接失败: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, "无效的响应")
                return
            }
            
            if httpResponse.statusCode == 200 {
                completion(true, "服务器连接正常")
            } else {
                completion(false, "服务器响应错误: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - HTTP方法枚举
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - 网络错误枚举
enum NetworkError: Error, LocalizedError {
    case noConnection
    case requestFailed(String)
    case invalidResponse
    case invalidData
    case unauthorized
    case forbidden
    case rateLimited
    case serverError
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "网络连接不可用"
        case .requestFailed(let message):
            return "请求失败: \(message)"
        case .invalidResponse:
            return "无效的服务器响应"
        case .invalidData:
            return "无效的数据格式"
        case .unauthorized:
            return "未授权访问，请重新登录"
        case .forbidden:
            return "访问被禁止"
        case .rateLimited:
            return "请求过于频繁，请稍后再试"
        case .serverError:
            return "服务器内部错误"
        case .decodingError(let message):
            return "数据解析错误: \(message)"
        }
    }
}

// MARK: - API响应模型
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
    let errors: [APIError]?
}

struct APIError: Codable {
    let field: String?
    let message: String
}

// MARK: - 扩展：UserDefaults安全存储
extension UserDefaults {
    func setSecureString(_ value: String, forKey key: String) {
        // 在实际项目中，应该使用Keychain存储敏感信息
        set(value, forKey: key)
    }
    
    func secureString(forKey key: String) -> String? {
        // 在实际项目中，应该从Keychain读取敏感信息
        return string(forKey: key)
    }
}

// MARK: - 配置验证
extension DatabaseConfig {
    func validateConfiguration() -> Bool {
        guard !apiKey.isEmpty else {
            print("❌ API密钥未配置")
            return false
        }
        
        guard !baseURL.isEmpty else {
            print("❌ 服务器地址未配置")
            return false
        }
        
        guard port > 0 && port <= 65535 else {
            print("❌ 端口号无效")
            return false
        }
        
        return true
    }
} 