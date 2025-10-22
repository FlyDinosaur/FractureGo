// FractureGo Interfaces - 所有接口定义的统一入口
// 此文件确保接口与实现完全分离，遵循MVC架构模式

import Foundation
import SwiftUI
import Combine
import CoreData

// MARK: - 模型接口导入
// 用户相关数据模型协议
// - UserModelProtocol: 用户基础信息
// - UserAuthModelProtocol: 用户认证信息  
// - CheckInRecordProtocol: 用户打卡记录
// - ForumContentProtocol: 论坛内容模型
// 枚举: UserType, Gender, LoginType, RecoveryType

// MARK: - 服务接口导入  
// 认证服务 - AuthServiceProtocol
// - 账户密码登录、微信登录、游客登录
// - 用户注册、验证码发送、密码重置
// - 自动登录检查、登出、用户信息更新

// 数据服务 - DataServiceProtocol, CheckInServiceProtocol, ForumServiceProtocol
// - Core Data操作、打卡记录管理
// - 论坛内容管理、用户数据服务
// - 关卡数据服务、特殊日期管理

// 工具服务 - UtilityProtocols
// - 加密服务、验证服务、网络服务
// - 文件管理、通知服务、缓存服务
// - 日志服务、分析服务、设备信息
// - 权限服务

// MARK: - 视图接口导入
// 视图协议 - ViewProtocols
// - SplashViewProtocol: 启动页面
// - LoginViewProtocol: 登录相关视图
// - MainTabViewProtocol: 主界面标签页
// - HomeViewProtocol: 应用主页
// - CheckInCalendarViewProtocol: 打卡日历
// - ForumViewProtocol: 论坛界面
// - ProfileViewProtocol: 个人主页
// - 其他辅助视图协议

// MARK: - 控制器接口导入
// ViewModel协议 - ViewModelProtocols  
// - BaseViewModelProtocol: 基础ViewModel
// - 各页面对应的ViewModel协议
// - 状态管理、数据绑定、业务逻辑处理

// 协调器协议 - CoordinatorProtocols
// - CoordinatorProtocol: 基础协调器
// - AppCoordinatorProtocol: 应用级协调器
// - AuthCoordinatorProtocol: 认证流程协调器
// - MainCoordinatorProtocol: 主界面协调器
// - 依赖注入容器、视图工厂、路由管理

// MARK: - 接口使用说明
/*
 * 1. 所有具体实现必须遵循对应的接口协议
 * 2. 接口定义了完整的方法签名和属性要求
 * 3. 使用依赖注入确保接口与实现解耦
 * 4. 遵循MVC架构，Model-View-Controller分离
 * 5. 支持单元测试，可轻松Mock接口进行测试
 * 6. 便于团队协作开发，接口作为开发契约
 */

// MARK: - 应用主要流程接口契约
/*
 启动流程:
 SplashViewModelProtocol -> AuthCoordinatorProtocol -> LoginViewModelProtocol
 
 认证流程:
 AuthServiceProtocol -> UserModelProtocol -> MainCoordinatorProtocol
 
 主界面流程:
 MainTabViewModelProtocol -> 各功能ViewModel -> 对应Service
 
 数据流程:
 ViewModel -> Service -> Core Data -> Model Protocol
 */ 