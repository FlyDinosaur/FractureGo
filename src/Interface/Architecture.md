# FractureGo 项目架构设计文档

## 项目概述
FractureGo 是一个面向骨折康复的iOS应用，采用SwiftUI开发，支持儿童、家长、医生三种用户类型。

## 架构模式
采用**MVC (Model-View-Controller)** 架构模式，结合**依赖注入**和**协调器模式**确保代码的可测试性和可维护性。

## 目录结构

```
Interface/
├── Models/                     # 数据模型接口
│   └── UserModels.swift       # 用户相关模型协议
├── Views/                      # 视图接口
│   └── ViewProtocols.swift    # 所有视图协议定义
├── Controllers/                # 控制器接口
│   ├── ViewModelProtocols.swift    # ViewModel协议
│   └── CoordinatorProtocols.swift  # 协调器和依赖注入协议
├── Services/                   # 服务层接口
│   ├── AuthServiceProtocol.swift     # 认证服务协议
│   ├── DataServiceProtocol.swift     # 数据服务协议
│   └── UtilityProtocols.swift        # 工具服务协议
├── FractureGoInterfaces.swift # 总接口导入文件
└── Architecture.md            # 本文档
```

## 核心特性

### 1. 登录认证系统
- **开屏页面**: 显示产品图标，初始化应用
- **登录方式**: 
  - 微信登录 (首次需补充信息)
  - 账户密码登录
  - 游客登录
- **用户注册**: 支持用户名、密码、手机号、性别、出生日期
- **密码安全**: MD5加密存储
- **忘记密码**: 手机验证码重置

### 2. 用户类型管理
- **儿童用户**: 康复训练主体
- **家长用户**: 监护和协助康复
- **医生用户**: 专业指导和监督

### 3. 主要功能模块

#### 应用主页
- 3个可滑动的康复卡片（手部、手臂、腿部）
- 循环滑动展示
- 点击跳转对应关卡界面

#### 打卡日历
- 月度日历展示
- 打卡状态可视化 (#9ecd57圆点)
- 连续打卡天数统计
- 特殊日期标记 (ICON_GIFT, ICON_STAR)
- 吉祥物鼓励提示

#### 康复训练
- 垂直布局的三个康复类型
- 关卡系统管理
- 进度跟踪

#### 论坛社区
- 双列瀑布流布局
- 内容搜索功能
- 发布、点赞交互
- 用户头像和昵称展示

#### 个人中心
- 用户信息展示
- 头像更换
- 设置管理
- 账户退出

### 4. 数据存储
- **Core Data**: 本地数据持久化
- **用户数据**: 加密存储敏感信息
- **缓存机制**: 提升应用性能

## 技术实现

### 接口分离设计
所有业务逻辑通过接口协议定义，具体实现与接口完全分离：

```swift
// 示例：认证服务接口
protocol AuthServiceProtocol {
    func login(phoneNumber: String, password: String) -> AnyPublisher<UserModelProtocol, AuthError>
    func wechatLogin() -> AnyPublisher<String, AuthError>
    // ... 其他方法
}
```

### 依赖注入
使用依赖注入容器管理所有服务和ViewModel的创建：

```swift
protocol DependencyContainerProtocol {
    func makeAuthService() -> AuthServiceProtocol
    func makeLoginViewModel() -> any LoginViewModelProtocol
    // ... 其他工厂方法
}
```

### 协调器模式
使用协调器管理页面导航和状态：

```swift
protocol AppCoordinatorProtocol: CoordinatorProtocol {
    func startApp()
    func handleDeepLink(_ url: URL)
    func logout()
}
```

## 开发优势

### 1. 可测试性
- 所有依赖都是协议，便于Mock测试
- ViewModel与View分离，逻辑单独测试
- 服务层独立，可单元测试

### 2. 可维护性
- 接口与实现分离，修改实现不影响接口
- 模块化设计，职责清晰
- 统一的错误处理机制

### 3. 团队协作
- 接口作为开发契约，前期定义好接口
- 不同开发者可并行开发不同模块
- 减少代码冲突

### 4. 扩展性
- 新增功能只需实现对应接口
- 支持插件式架构
- 便于功能模块替换

## 实现指南

### 1. 开发流程
1. 根据需求定义接口协议
2. 创建Mock实现用于测试
3. 开发真实实现类
4. 通过依赖注入注册服务
5. 编写单元测试验证

### 2. 命名规范
- **协议命名**: `XXXProtocol`
- **ViewModel**: `XXXViewModelProtocol`
- **服务类**: `XXXServiceProtocol`
- **错误类型**: `XXXError`

### 3. 代码组织
- 每个模块的接口和实现分别放在不同文件夹
- 使用MARK注释组织代码结构
- 统一导入必要的系统框架

## 后续开发建议

1. **先实现核心功能**: 认证系统 → 主界面 → 打卡功能
2. **渐进式开发**: 先实现基础版本，再逐步添加高级功能
3. **测试驱动**: 每个功能都要有对应的单元测试
4. **性能优化**: 关注Core Data性能，适当使用缓存
5. **用户体验**: 重视界面交互和动画效果

这个架构设计确保了项目的可扩展性和可维护性，为后续的团队协作开发奠定了坚实的基础。 