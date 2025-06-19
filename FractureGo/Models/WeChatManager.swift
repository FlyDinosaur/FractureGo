//
//  WeChatManager.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import Foundation
// import WechatOpenSDK // 暂时注释掉，等待真正的微信SDK集成

// 微信用户信息结构
struct WeChatUserInfo {
    let openId: String
    let nickname: String
    let avatarUrl: String
    let unionId: String?
}

// 微信登录结果
enum WeChatLoginResult {
    case success(WeChatUserInfo)
    case cancelled
    case error(String)
}

// 微信登录管理器
class WeChatManager: NSObject, ObservableObject {
    static let shared = WeChatManager()
    
    // 微信应用配置 - 需要在微信开放平台申请
    private let appId = "your_wechat_app_id" // 替换为实际的微信AppID
    private let appSecret = "your_wechat_app_secret" // 替换为实际的微信AppSecret
    
    // 登录回调
    private var loginCompletion: ((WeChatLoginResult) -> Void)?
    
    @Published var isLoggedIn = false
    @Published var userInfo: WeChatUserInfo?
    
    private override init() {
        super.init()
        // 暂时注释掉微信SDK注册
        // registerWeChatApp()
    }
    
    // 注册微信应用
    private func registerWeChatApp() {
        // WXApi.registerApp(appId)
        print("微信SDK注册 - 需要真正的微信SDK")
    }
    
    // 检查是否安装微信
    func isWeChatInstalled() -> Bool {
        // return WXApi.isWXAppInstalled()
        return true // 模拟返回true
    }
    
    // 检查微信版本是否支持OpenAPI
    func isWeChatSupportApi() -> Bool {
        // return WXApi.isWXAppSupport()
        return true // 模拟返回true
    }
    
    // 发起微信登录
    func login(completion: @escaping (WeChatLoginResult) -> Void) {
        print("开始微信登录")
        self.loginCompletion = completion
        
        // 模拟微信登录流程
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let mockUserInfo = WeChatUserInfo(
                openId: "mock_wechat_openid_\(Int.random(in: 1000...9999))",
                nickname: "微信用户\(Int.random(in: 100...999))",
                avatarUrl: "https://example.com/avatar.jpg",
                unionId: nil
            )
            completion(.success(mockUserInfo))
        }
        
        /* 真正的微信登录代码（需要集成微信SDK后启用）:
        guard isWeChatInstalled() else {
            completion(.error("未安装微信"))
            return
        }
        
        let req = SendAuthReq()
        req.scope = "snsapi_userinfo"
        req.state = "wechat_sdk_demo_test"
        
        WXApi.send(req) { (result) in
            if !result {
                completion(.error("发起微信登录失败"))
            }
        }
        */
    }
    
    // 处理微信回调URL
    func handleOpenURL(_ url: URL) -> Bool {
        print("处理微信回调URL: \(url)")
        // return WXApi.handleOpen(url, delegate: self)
        return true // 模拟返回true
    }
    
    // 获取用户信息
    private func fetchUserInfo(accessToken: String, openId: String) {
        let urlString = "https://api.weixin.qq.com/sns/userinfo?access_token=\(accessToken)&openid=\(openId)"
        
        guard let url = URL(string: urlString) else {
            loginCompletion?(.error("请求用户信息失败"))
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.loginCompletion?(.error("获取用户信息失败: \(error.localizedDescription)"))
                    return
                }
                
                guard let data = data else {
                    self?.loginCompletion?(.error("获取用户信息失败"))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let errcode = json["errcode"] as? Int, errcode != 0 {
                            let errmsg = json["errmsg"] as? String ?? "未知错误"
                            self?.loginCompletion?(.error("获取用户信息失败: \(errmsg)"))
                            return
                        }
                        
                        let openId = json["openid"] as? String ?? ""
                        let nickname = json["nickname"] as? String ?? ""
                        let headImgUrl = json["headimgurl"] as? String ?? ""
                        let unionId = json["unionid"] as? String
                        
                        let userInfo = WeChatUserInfo(
                            openId: openId,
                            nickname: nickname,
                            avatarUrl: headImgUrl,
                            unionId: unionId
                        )
                        
                        self?.userInfo = userInfo
                        self?.isLoggedIn = true
                        self?.loginCompletion?(.success(userInfo))
                    }
                } catch {
                    self?.loginCompletion?(.error("解析用户信息失败"))
                }
            }
        }.resume()
    }
    
    // 获取访问令牌
    private func fetchAccessToken(code: String) {
        let urlString = "https://api.weixin.qq.com/sns/oauth2/access_token?appid=\(appId)&secret=\(appSecret)&code=\(code)&grant_type=authorization_code"
        
        guard let url = URL(string: urlString) else {
            loginCompletion?(.error("获取访问令牌失败"))
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.loginCompletion?(.error("获取访问令牌失败: \(error.localizedDescription)"))
                    return
                }
                
                guard let data = data else {
                    self?.loginCompletion?(.error("获取访问令牌失败"))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let errcode = json["errcode"] as? Int {
                            let errmsg = json["errmsg"] as? String ?? "未知错误"
                            self?.loginCompletion?(.error("获取访问令牌失败: \(errmsg)"))
                            return
                        }
                        
                        guard let accessToken = json["access_token"] as? String,
                              let openId = json["openid"] as? String else {
                            self?.loginCompletion?(.error("获取访问令牌失败"))
                            return
                        }
                        
                        // 获取用户信息
                        self?.fetchUserInfo(accessToken: accessToken, openId: openId)
                    }
                } catch {
                    self?.loginCompletion?(.error("解析访问令牌失败"))
                }
            }
        }.resume()
    }
    
    // 登出
    func logout() {
        isLoggedIn = false
        userInfo = nil
    }
}

// 微信API委托（需要真正的微信SDK后启用）
/*
extension WeChatManager: WXApiDelegate {
    func onReq(_ req: BaseReq) {
        // 处理微信请求
    }
    
    func onResp(_ resp: BaseResp) {
        print("微信回调: \(resp)")
        
        guard let authResp = resp as? SendAuthResp else {
            loginCompletion?(.error("无效的微信回调"))
            return
        }
        
        switch authResp.errCode {
        case WXSuccess.rawValue:
            // 获取用户信息
            if let code = authResp.code {
                getUserInfo(with: code)
            } else {
                loginCompletion?(.error("获取授权码失败"))
            }
        case WXErrCodeUserCancel.rawValue:
            loginCompletion?(.cancelled)
        default:
            loginCompletion?(.error("微信登录失败: \(authResp.errStr ?? "未知错误")"))
        }
    }
    
    private func getUserInfo(with code: String) {
        // 通过code获取access_token和用户信息
        // 这里需要调用您的后端API来换取用户信息
        // 为了演示，这里使用模拟数据
        
        let mockUserInfo = WeChatUserInfo(
            openId: "real_wechat_openid_from_api",
            nickname: "真实微信用户",
            avatarUrl: "https://real-avatar-url.com/avatar.jpg",
            unionId: "union_id_if_available"
        )
        
        DispatchQueue.main.async {
            self.userInfo = mockUserInfo
            self.isLoggedIn = true
            self.loginCompletion?(.success(mockUserInfo))
        }
    }
}
*/ 