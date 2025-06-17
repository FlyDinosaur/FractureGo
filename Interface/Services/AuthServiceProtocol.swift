import Foundation
import Combine

// MARK: - 认证服务协议
protocol AuthServiceProtocol {
    // 账户密码登录
    func login(phoneNumber: String, password: String) -> AnyPublisher<UserModelProtocol, AuthError>
    
    // 微信登录
    func wechatLogin() -> AnyPublisher<String, AuthError> // 返回openID
    
    // 游客登录
    func guestLogin() -> AnyPublisher<UserModelProtocol, AuthError>
    
    // 注册账户
    func register(username: String, 
                 userType: UserType,
                 password: String,
                 phoneNumber: String,
                 gender: Gender,
                 birthDate: Date) -> AnyPublisher<UserModelProtocol, AuthError>
    
    // 发送验证码
    func sendVerificationCode(phoneNumber: String) -> AnyPublisher<Bool, AuthError>
    
    // 验证验证码
    func verifyCode(phoneNumber: String, code: String) -> AnyPublisher<Bool, AuthError>
    
    // 重置密码
    func resetPassword(phoneNumber: String, newPassword: String, verificationCode: String) -> AnyPublisher<Bool, AuthError>
    
    // 自动登录检查
    func checkAutoLogin() -> AnyPublisher<UserModelProtocol?, AuthError>
    
    // 登出
    func logout() -> AnyPublisher<Bool, AuthError>
    
    // 获取当前用户
    func getCurrentUser() -> UserModelProtocol?
    
    // 更新用户信息（微信登录后填写）
    func updateUserInfo(userID: String, 
                       username: String,
                       userType: UserType,
                       phoneNumber: String,
                       gender: Gender,
                       birthDate: Date) -> AnyPublisher<UserModelProtocol, AuthError>
}

// MARK: - 认证错误枚举
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case userNotFound
    case phoneNumberExists
    case invalidPhoneNumber
    case verificationCodeError
    case wechatLoginFailed
    case networkError
    case dataError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "用户名或密码错误"
        case .userNotFound:
            return "用户不存在"
        case .phoneNumberExists:
            return "手机号已存在"
        case .invalidPhoneNumber:
            return "手机号格式错误"
        case .verificationCodeError:
            return "验证码错误"
        case .wechatLoginFailed:
            return "微信登录失败"
        case .networkError:
            return "网络连接错误"
        case .dataError:
            return "数据错误"
        case .unknown(let message):
            return message
        }
    }
} 