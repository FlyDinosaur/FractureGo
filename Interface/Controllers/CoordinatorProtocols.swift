import Foundation
import SwiftUI
import Combine

// MARK: - 基础协调器协议
protocol CoordinatorProtocol: ObservableObject {
    associatedtype Route
    
    var navigationPath: NavigationPath { get set }
    var sheet: AnyView? { get set }
    var fullScreenCover: AnyView? { get set }
    
    func navigate(to route: Route)
    func navigateBack()
    func navigateToRoot()
    func presentSheet<T: View>(_ view: T)
    func presentFullScreenCover<T: View>(_ view: T)
    func dismissSheet()
    func dismissFullScreenCover()
}

// MARK: - 应用协调器协议
protocol AppCoordinatorProtocol: CoordinatorProtocol where Route == AppRoute {
    var isUserLoggedIn: Bool { get set }
    var currentUserType: UserType? { get set }
    
    func startApp()
    func handleDeepLink(_ url: URL)
    func logout()
}

// MARK: - 认证协调器协议
protocol AuthCoordinatorProtocol: CoordinatorProtocol where Route == AuthRoute {
    func showLogin()
    func showRegister()
    func showForgotPassword()
    func showUserInfoCompletion(wechatOpenID: String)
    func completeAuthentication(user: UserModelProtocol)
}

// MARK: - 主界面协调器协议
protocol MainCoordinatorProtocol: CoordinatorProtocol where Route == MainRoute {
    var selectedTab: String { get set }
    var currentUser: UserModelProtocol { get set }
    
    func switchTab(_ tab: String)
    func navigateToRecoveryLevel(_ type: RecoveryType)
    func navigateToProfile()
    func navigateToSettings()
}

// MARK: - 路由枚举定义
enum AppRoute {
    case splash
    case auth
    case main(UserModelProtocol)
}

enum AuthRoute {
    case login
    case register
    case forgotPassword
    case userInfoCompletion(String) // wechatOpenID
}

enum MainRoute {
    case home
    case checkInCalendar
    case recoveryMain
    case forum
    case profile
    case handLevel
    case armLevel
    case legLevel
    case settings
    case contentPublish
}

// MARK: - 依赖注入容器协议
protocol DependencyContainerProtocol {
    // Services
    func makeAuthService() -> AuthServiceProtocol
    func makeDataService() -> DataServiceProtocol
    func makeCheckInService() -> CheckInServiceProtocol
    func makeForumService() -> ForumServiceProtocol
    func makeUserDataService() -> UserDataServiceProtocol
    func makeLevelService() -> LevelServiceProtocol
    
    // ViewModels
    func makeSplashViewModel() -> any SplashViewModelProtocol
    func makeLoginViewModel() -> any LoginViewModelProtocol
    func makeRegisterViewModel() -> any RegisterViewModelProtocol
    func makeForgotPasswordViewModel() -> any ForgotPasswordViewModelProtocol
    func makeUserInfoCompletionViewModel(wechatOpenID: String) -> any UserInfoCompletionViewModelProtocol
    func makeMainTabViewModel(user: UserModelProtocol) -> any MainTabViewModelProtocol
    func makeHomeViewModel() -> any HomeViewModelProtocol
    func makeCheckInCalendarViewModel() -> any CheckInCalendarViewModelProtocol
    func makeRecoveryMainViewModel() -> any RecoveryMainViewModelProtocol
    func makeLevelViewModel(recoveryType: RecoveryType) -> any LevelViewModelProtocol
    func makeForumViewModel() -> any ForumViewModelProtocol
    func makeProfileViewModel() -> any ProfileViewModelProtocol
    func makeSettingsViewModel() -> any SettingsViewModelProtocol
    func makeContentPublishViewModel() -> any ContentPublishViewModelProtocol
    
    // Coordinators
    func makeAppCoordinator() -> any AppCoordinatorProtocol
    func makeAuthCoordinator() -> any AuthCoordinatorProtocol
    func makeMainCoordinator(user: UserModelProtocol) -> any MainCoordinatorProtocol
}

// MARK: - 视图工厂协议
protocol ViewFactoryProtocol {
    func makeSplashView() -> AnyView
    func makeLoginView() -> AnyView
    func makeRegisterView() -> AnyView
    func makeForgotPasswordView() -> AnyView
    func makeUserInfoCompletionView(wechatOpenID: String) -> AnyView
    func makeMainTabView(user: UserModelProtocol) -> AnyView
    func makeHomeView() -> AnyView
    func makeCheckInCalendarView() -> AnyView
    func makeRecoveryMainView() -> AnyView
    func makeLevelView(recoveryType: RecoveryType) -> AnyView
    func makeForumView() -> AnyView
    func makeProfileView() -> AnyView
    func makeSettingsView() -> AnyView
    func makeContentPublishView() -> AnyView
}

// MARK: - 应用配置协议
protocol AppConfigurationProtocol {
    var apiBaseURL: String { get }
    var wechatAppID: String { get }
    var isDebugMode: Bool { get }
    var coreDataModelName: String { get }
    var encryptionKey: String { get }
    
    func configure()
}

// MARK: - 错误处理协议
protocol ErrorHandlerProtocol {
    func handle(_ error: Error)
    func showAlert(title: String, message: String)
    func showToast(_ message: String)
    func logError(_ error: Error)
}

// MARK: - 路由器协议
protocol RouterProtocol {
    associatedtype Route
    
    func canHandle(_ route: Route) -> Bool
    func handle(_ route: Route)
    func buildView(for route: Route) -> AnyView
} 