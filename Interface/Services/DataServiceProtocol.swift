import Foundation
import Combine
import CoreData

// MARK: - 数据服务协议
protocol DataServiceProtocol {
    // Core Data 相关
    var viewContext: NSManagedObjectContext { get }
    func saveContext() -> AnyPublisher<Bool, DataError>
}

// MARK: - 打卡服务协议
protocol CheckInServiceProtocol {
    // 添加打卡记录
    func addCheckInRecord(userID: String, recoveryType: RecoveryType) -> AnyPublisher<CheckInRecordProtocol, DataError>
    
    // 获取用户打卡记录
    func getCheckInRecords(userID: String, month: Date) -> AnyPublisher<[CheckInRecordProtocol], DataError>
    
    // 获取连续打卡天数
    func getConsecutiveDays(userID: String) -> AnyPublisher<Int, DataError>
    
    // 检查特殊日期
    func getSpecialDates(month: Date) -> AnyPublisher<[SpecialDate], DataError>
    
    // 生成鼓励提示
    func getEncouragementTip(consecutiveDays: Int) -> String
}

// MARK: - 论坛服务协议
protocol ForumServiceProtocol {
    // 获取论坛内容列表
    func getForumContents(page: Int, pageSize: Int) -> AnyPublisher<[ForumContentProtocol], DataError>
    
    // 搜索论坛内容
    func searchForumContents(keyword: String) -> AnyPublisher<[ForumContentProtocol], DataError>
    
    // 发布内容
    func publishContent(userID: String, title: String, imageName: String) -> AnyPublisher<ForumContentProtocol, DataError>
    
    // 点赞
    func likeContent(contentID: String) -> AnyPublisher<Bool, DataError>
    
    // 取消点赞
    func unlikeContent(contentID: String) -> AnyPublisher<Bool, DataError>
}

// MARK: - 用户数据服务协议
protocol UserDataServiceProtocol {
    // 获取用户信息
    func getUserInfo(userID: String) -> AnyPublisher<UserModelProtocol, DataError>
    
    // 更新用户信息
    func updateUserInfo(_ user: UserModelProtocol) -> AnyPublisher<UserModelProtocol, DataError>
    
    // 更新头像
    func updateAvatar(userID: String, avatarPath: String) -> AnyPublisher<Bool, DataError>
    
    // 删除用户账户
    func deleteUser(userID: String) -> AnyPublisher<Bool, DataError>
}

// MARK: - 关卡数据服务协议
protocol LevelServiceProtocol {
    // 获取关卡列表
    func getLevels(recoveryType: RecoveryType) -> AnyPublisher<[LevelInfo], DataError>
    
    // 更新关卡进度
    func updateLevelProgress(userID: String, levelID: String, progress: Int) -> AnyPublisher<Bool, DataError>
    
    // 获取用户关卡进度
    func getUserLevelProgress(userID: String, recoveryType: RecoveryType) -> AnyPublisher<[UserLevelProgress], DataError>
}

// MARK: - 特殊日期模型
struct SpecialDate {
    let date: Date
    let type: SpecialDateType
}

enum SpecialDateType: String {
    case gift = "ICON_GIFT"
    case star = "ICON_STAR"
}

// MARK: - 关卡信息模型
struct LevelInfo: Identifiable {
    let id: String
    let name: String
    let description: String
    let recoveryType: RecoveryType
    let difficulty: Int
    let imageName: String
}

// MARK: - 用户关卡进度模型
struct UserLevelProgress: Identifiable {
    let id: String
    let userID: String
    let levelID: String
    let progress: Int // 0-100
    let completed: Bool
    let completedAt: Date?
}

// MARK: - 数据错误枚举
enum DataError: Error, LocalizedError {
    case coreDataError(String)
    case notFound
    case invalidData
    case networkError
    case permissionDenied
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .coreDataError(let message):
            return "数据库错误: \(message)"
        case .notFound:
            return "数据未找到"
        case .invalidData:
            return "数据格式错误"
        case .networkError:
            return "网络连接错误"
        case .permissionDenied:
            return "权限不足"
        case .unknown(let message):
            return message
        }
    }
} 