import Foundation
import Combine
import SwiftUI

// MARK: - 基础ViewModel协议
protocol BaseViewModelProtocol: ObservableObject {
    var viewState: ViewState { get set }
    var cancellables: Set<AnyCancellable> { get set }
    
    func handleError(_ error: Error)
    func showLoading()
    func hideLoading()
}

// MARK: - 启动页面ViewModel协议
protocol SplashViewModelProtocol: BaseViewModelProtocol {
    var isAppReady: Bool { get set }
    
    func initialize()
    func checkAppVersion()
    func loadInitialData()
}

// MARK: - 登录ViewModel协议
protocol LoginViewModelProtocol: BaseViewModelProtocol {
    var phoneNumber: String { get set }
    var password: String { get set }
    var isAutoLogin: Bool { get set }
    var isLoggedIn: Bool { get set }
    
    func login()
    func wechatLogin()
    func guestLogin()
    func checkAutoLogin()
}

// MARK: - 注册ViewModel协议
protocol RegisterViewModelProtocol: BaseViewModelProtocol {
    var username: String { get set }
    var selectedUserType: UserType { get set }
    var password: String { get set }
    var confirmPassword: String { get set }
    var phoneNumber: String { get set }
    var selectedGender: Gender { get set }
    var birthDate: Date { get set }
    var isRegistrationSuccess: Bool { get set }
    
    func register()
    func validateInput() -> Bool
}

// MARK: - 忘记密码ViewModel协议
protocol ForgotPasswordViewModelProtocol: BaseViewModelProtocol {
    var phoneNumber: String { get set }
    var verificationCode: String { get set }
    var newPassword: String { get set }
    var confirmPassword: String { get set }
    var isCodeSent: Bool { get set }
    var countdownTime: Int { get set }
    
    func sendVerificationCode()
    func verifyCodeAndResetPassword()
    func startCountdown()
}

// MARK: - 用户信息完善ViewModel协议
protocol UserInfoCompletionViewModelProtocol: BaseViewModelProtocol {
    var username: String { get set }
    var selectedUserType: UserType { get set }
    var phoneNumber: String { get set }
    var selectedGender: Gender { get set }
    var birthDate: Date { get set }
    var wechatOpenID: String { get }
    
    func completeUserInfo()
    func validateInput() -> Bool
}

// MARK: - 主界面ViewModel协议
protocol MainTabViewModelProtocol: BaseViewModelProtocol {
    var selectedTab: String { get set }
    var currentUser: UserModelProtocol? { get set }
    
    func switchTab(_ tab: String)
    func loadUserData()
}

// MARK: - 首页ViewModel协议
protocol HomeViewModelProtocol: BaseViewModelProtocol {
    var currentCardIndex: Int { get set }
    var recoveryCards: [RecoveryCard] { get set }
    
    func nextCard()
    func previousCard()
    func selectRecoveryType(_ type: RecoveryType)
}

// MARK: - 打卡日历ViewModel协议
protocol CheckInCalendarViewModelProtocol: BaseViewModelProtocol {
    var selectedMonth: Date { get set }
    var checkInRecords: [CheckInRecordProtocol] { get set }
    var specialDates: [SpecialDate] { get set }
    var consecutiveDays: Int { get set }
    var encouragementTip: String { get set }
    var mascotImage: String { get set }
    
    func loadCheckInData()
    func changeMonth(_ month: Date)
    func addCheckIn(_ type: RecoveryType)
    func updateConsecutiveDays()
}

// MARK: - 恢复训练ViewModel协议
protocol RecoveryMainViewModelProtocol: BaseViewModelProtocol {
    var handProgress: Int { get set }
    var armProgress: Int { get set }
    var legProgress: Int { get set }
    
    func loadProgress()
    func navigateToLevel(_ type: RecoveryType)
}

// MARK: - 关卡ViewModel协议
protocol LevelViewModelProtocol: BaseViewModelProtocol {
    var recoveryType: RecoveryType { get set }
    var levels: [LevelInfo] { get set }
    var userProgress: [UserLevelProgress] { get set }
    
    func loadLevels()
    func startLevel(_ levelID: String)
    func updateProgress(_ levelID: String, progress: Int)
}

// MARK: - 论坛ViewModel协议
protocol ForumViewModelProtocol: BaseViewModelProtocol {
    var forumContents: [ForumContentProtocol] { get set }
    var searchText: String { get set }
    var currentUser: UserModelProtocol? { get set }
    var isSearching: Bool { get set }
    
    func loadForumContents()
    func searchContents(_ keyword: String)
    func likeContent(_ contentID: String)
    func unlikeContent(_ contentID: String)
    func refreshData()
}

// MARK: - 个人主页ViewModel协议
protocol ProfileViewModelProtocol: BaseViewModelProtocol {
    var currentUser: UserModelProtocol? { get set }
    var avatar: String? { get set }
    
    func loadUserProfile()
    func updateAvatar(_ imagePath: String)
    func logout()
    func deleteAccount()
}

// MARK: - 设置ViewModel协议
protocol SettingsViewModelProtocol: BaseViewModelProtocol {
    var notificationsEnabled: Bool { get set }
    var privacySettings: PrivacySettings { get set }
    
    func updateNotificationSettings()
    func updatePrivacySettings()
    func clearCache()
    func exportData()
}

// MARK: - 内容发布ViewModel协议
protocol ContentPublishViewModelProtocol: BaseViewModelProtocol {
    var title: String { get set }
    var selectedImageName: String? { get set }
    var availableImages: [String] { get set }
    
    func loadAvailableImages()
    func publishContent()
    func validateContent() -> Bool
}

// MARK: - 恢复卡片模型
struct RecoveryCard: Identifiable {
    let id = UUID()
    let type: RecoveryType
    let imageName: String
    let title: String
    let description: String
}

// MARK: - 隐私设置模型
struct PrivacySettings {
    var dataCollection: Bool
    var analytics: Bool
    var personalizedAds: Bool
    var locationTracking: Bool
}

// MARK: - ViewModel状态管理协议
protocol ViewModelStateProtocol {
    func resetToInitialState()
    func saveState()
    func restoreState()
} 