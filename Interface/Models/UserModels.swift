import Foundation
import CoreData

// MARK: - 用户类型枚举
enum UserType: String, CaseIterable {
    case child = "儿童"
    case parent = "家长" 
    case doctor = "医生"
}

// MARK: - 性别枚举
enum Gender: String, CaseIterable {
    case male = "男"
    case female = "女"
    case other = "其他"
}

// MARK: - 登录方式枚举
enum LoginType {
    case wechat
    case account
    case guest
}

// MARK: - 用户数据模型协议
protocol UserModelProtocol {
    var userID: String { get set }
    var username: String { get set }
    var userType: UserType { get set }
    var phoneNumber: String { get set }
    var gender: Gender { get set }
    var birthDate: Date { get set }
    var avatar: String? { get set }
    var isWechatUser: Bool { get set }
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
}

// MARK: - 用户认证数据模型协议
protocol UserAuthModelProtocol {
    var userID: String { get set }
    var passwordHash: String { get set }
    var wechatOpenID: String? { get set }
    var isAutoLogin: Bool { get set }
    var lastLoginTime: Date? { get set }
}

// MARK: - 打卡记录模型协议
protocol CheckInRecordProtocol {
    var recordID: String { get set }
    var userID: String { get set }
    var checkInDate: Date { get set }
    var consecutiveDays: Int { get set }
    var recoveryType: RecoveryType { get set }
}

// MARK: - 恢复类型枚举
enum RecoveryType: String, CaseIterable {
    case hand = "手部恢复"
    case arm = "手臂恢复"
    case leg = "腿部恢复"
}

// MARK: - 论坛内容模型协议
protocol ForumContentProtocol {
    var contentID: String { get set }
    var userID: String { get set }
    var title: String { get set }
    var imageName: String { get set }
    var createdAt: Date { get set }
    var likeCount: Int { get set }
    var commentCount: Int { get set }
} 