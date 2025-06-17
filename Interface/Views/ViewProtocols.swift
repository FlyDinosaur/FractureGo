import SwiftUI
import Combine

// MARK: - 基础视图协议
protocol BaseViewProtocol: View {
    associatedtype ViewModel: ObservableObject
    var viewModel: ViewModel { get }
}

// MARK: - 启动页面协议
protocol SplashViewProtocol: BaseViewProtocol {
    func startApp()
}

// MARK: - 登录相关视图协议
protocol LoginViewProtocol: BaseViewProtocol {
    func onWechatLogin()
    func onAccountLogin(phoneNumber: String, password: String)
    func onGuestLogin()
    func onForgotPassword()
    func onRegister()
}

protocol RegisterViewProtocol: BaseViewProtocol {
    func onRegister(username: String, userType: UserType, password: String, phoneNumber: String, gender: Gender, birthDate: Date)
    func onBackToLogin()
}

protocol ForgotPasswordViewProtocol: BaseViewProtocol {
    func onSendVerificationCode(phoneNumber: String)
    func onResetPassword(phoneNumber: String, newPassword: String, verificationCode: String)
    func onBackToLogin()
}

protocol UserInfoCompletionViewProtocol: BaseViewProtocol {
    func onCompleteUserInfo(username: String, userType: UserType, phoneNumber: String, gender: Gender, birthDate: Date)
}

// MARK: - 主界面相关视图协议
protocol MainTabViewProtocol: BaseViewProtocol {
    var selectedTab: String { get set }
    func onTabSelected(_ tab: String)
}

// MARK: - 应用主页视图协议
protocol HomeViewProtocol: BaseViewProtocol {
    var currentCardIndex: Int { get set }
    func onCardSwipe(direction: SwipeDirection)
    func onCardTapped(recoveryType: RecoveryType)
}

enum SwipeDirection {
    case left, right
}

// MARK: - 打卡日历视图协议
protocol CheckInCalendarViewProtocol: BaseViewProtocol {
    var selectedMonth: Date { get set }
    var checkInRecords: [CheckInRecordProtocol] { get }
    var specialDates: [SpecialDate] { get }
    var consecutiveDays: Int { get }
    
    func onDateSelected(_ date: Date)
    func onMonthChanged(_ month: Date)
    func refreshCheckInData()
}

// MARK: - 恢复训练主页视图协议
protocol RecoveryMainViewProtocol: BaseViewProtocol {
    func onRecoveryTypeSelected(_ type: RecoveryType)
}

// MARK: - 关卡界面视图协议
protocol LevelViewProtocol: BaseViewProtocol {
    var recoveryType: RecoveryType { get }
    var levels: [LevelInfo] { get }
    var userProgress: [UserLevelProgress] { get }
    
    func onLevelSelected(_ level: LevelInfo)
    func refreshLevelData()
}

// MARK: - 论坛视图协议
protocol ForumViewProtocol: BaseViewProtocol {
    var forumContents: [ForumContentProtocol] { get }
    var searchText: String { get set }
    
    func onSearch(_ keyword: String)
    func onContentTapped(_ content: ForumContentProtocol)
    func onPublishContent()
    func onLikeContent(_ contentID: String)
    func refreshForumData()
}

// MARK: - 个人主页视图协议
protocol ProfileViewProtocol: BaseViewProtocol {
    var currentUser: UserModelProtocol? { get }
    
    func onEditProfile()
    func onSettings()
    func onLogout()
    func onAvatarTapped()
}

// MARK: - 设置页面视图协议
protocol SettingsViewProtocol: BaseViewProtocol {
    func onNotificationSettings()
    func onPrivacySettings()
    func onAbout()
    func onFeedback()
}

// MARK: - 内容发布视图协议
protocol ContentPublishViewProtocol: BaseViewProtocol {
    var title: String { get set }
    var selectedImage: String? { get set }
    
    func onImageSelected(_ imageName: String)
    func onPublish()
    func onCancel()
}

// MARK: - 视图状态枚举
enum ViewState {
    case idle
    case loading
    case loaded
    case error(String)
}

// MARK: - 视图动作协议
protocol ViewActionProtocol {
    func showLoading()
    func hideLoading()
    func showError(_ message: String)
    func showSuccess(_ message: String)
}

// MARK: - 导航协议
protocol NavigationProtocol {
    func navigateTo<T: View>(_ view: T)
    func navigateBack()
    func navigateToRoot()
} 