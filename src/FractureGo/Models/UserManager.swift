//
//  UserManager.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import Foundation
import SwiftUI

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var isLoggedIn = false
    @Published var currentUser: UserData?
    
    // 网络服务
    private let networkService = NetworkService.shared
    
    // 保存密码功能
    var savePassword: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "savePassword")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "savePassword")
        }
    }
    
    struct UserData {
        let nickname: String
        let phoneNumber: String
        let userType: String
        let birthDate: Date
        let isWeChatUser: Bool
        let wechatOpenId: String?
        let wechatNickname: String?
        let wechatAvatarUrl: String?
        
        init(nickname: String, phoneNumber: String, userType: String, birthDate: Date, isWeChatUser: Bool, wechatOpenId: String? = nil, wechatNickname: String? = nil, wechatAvatarUrl: String? = nil) {
            self.nickname = nickname
            self.phoneNumber = phoneNumber
            self.userType = userType
            self.birthDate = birthDate
            self.isWeChatUser = isWeChatUser
            self.wechatOpenId = wechatOpenId
            self.wechatNickname = wechatNickname
            self.wechatAvatarUrl = wechatAvatarUrl
        }
    }
    
    private init() {
        // 移除自动登录检查，改为由用户手动登录
    }
    
    func loginUser(phoneNumber: String, userData: [String: Any]) {
        loadUserData(from: userData, phoneNumber: phoneNumber)
        isLoggedIn = true
    }
    
    // 使用网络服务进行登录验证
    func validateLogin(phone: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        networkService.login(phoneNumber: phone, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let authResponse):
                    // 登录成功，更新用户信息
                    self?.updateCurrentUser(from: authResponse.user)
                    self?.isLoggedIn = true
                    completion(true, nil)
                case .failure(let error):
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    // 从网络响应更新当前用户信息
    private func updateCurrentUser(from networkUser: User) {
        let dateFormatter = ISO8601DateFormatter()
        let birthDate = dateFormatter.date(from: networkUser.birthDate) ?? Date()
        
        currentUser = UserData(
            nickname: networkUser.nickname,
            phoneNumber: networkUser.phoneNumber,
            userType: networkUser.userType,
            birthDate: birthDate,
            isWeChatUser: networkUser.isWeChatUser,
            wechatOpenId: nil, // 服务端不返回敏感信息
            wechatNickname: networkUser.wechatNickname,
            wechatAvatarUrl: networkUser.wechatAvatarUrl
        )
    }
    
    func saveUserSession(phone: String, password: String, savePassword: Bool) {
        if savePassword {
            UserDefaults.standard.set(true, forKey: "savePassword")
            UserDefaults.standard.set(phone, forKey: "savedPhoneNumber")
            UserDefaults.standard.set(password, forKey: "savedPassword_\(phone)")
        } else {
            UserDefaults.standard.removeObject(forKey: "savePassword")
            UserDefaults.standard.removeObject(forKey: "savedPhoneNumber")
            UserDefaults.standard.removeObject(forKey: "savedPassword_\(phone)")
        }
        
        if let userData = UserDefaults.standard.dictionary(forKey: "userData_\(phone)") {
            loadUserData(from: userData, phoneNumber: phone)
            isLoggedIn = true
        }
    }
    
    func getSavedPhoneNumber() -> String? {
        return UserDefaults.standard.string(forKey: "savedPhoneNumber")
    }
    
    func getSavedPassword(for phoneNumber: String) -> String? {
        if savePassword {
            return UserDefaults.standard.string(forKey: "savedPassword_\(phoneNumber)")
        }
        return nil
    }
    
    private func loadUserData(from userData: [String: Any], phoneNumber: String) {
        guard let nickname = userData["nickname"] as? String,
              let userType = userData["userType"] as? String,
              let birthDateTimestamp = userData["birthDate"] as? TimeInterval,
              let isWeChatUser = userData["isWeChatUser"] as? Bool else {
            return
        }
        
        let birthDate = Date(timeIntervalSince1970: birthDateTimestamp)
        
        // 获取微信相关信息（如果是微信用户）
        let wechatOpenId = userData["wechatOpenId"] as? String
        let wechatNickname = userData["wechatNickname"] as? String
        let wechatAvatarUrl = userData["wechatAvatarUrl"] as? String
        
        currentUser = UserData(
            nickname: nickname,
            phoneNumber: phoneNumber,
            userType: userType,
            birthDate: birthDate,
            isWeChatUser: isWeChatUser,
            wechatOpenId: wechatOpenId,
            wechatNickname: wechatNickname,
            wechatAvatarUrl: wechatAvatarUrl
        )
    }
    
    func logout() {
        isLoggedIn = false
        currentUser = nil
        // 清理保存的密码相关信息
        UserDefaults.standard.removeObject(forKey: "savePassword")
        UserDefaults.standard.removeObject(forKey: "savedPhoneNumber")
        if let phoneNumber = currentUser?.phoneNumber {
            UserDefaults.standard.removeObject(forKey: "savedPassword_\(phoneNumber)")
        }
    }
    
    // 检查微信用户是否存在
    func checkWeChatUserExists(openId: String) -> Bool {
        let userKeys = UserDefaults.standard.dictionaryRepresentation().keys
        
        for key in userKeys {
            if key.hasPrefix("userData_") {
                if let userData = UserDefaults.standard.dictionary(forKey: key),
                   let isWeChatUser = userData["isWeChatUser"] as? Bool,
                   let wechatOpenId = userData["wechatOpenId"] as? String,
                   isWeChatUser && wechatOpenId == openId {
                    return true
                }
            }
        }
        
        return false
    }
    
    // 微信用户直接登录
    func loginWeChatUser(wechatUserInfo: WeChatUserInfo) {
        let userKeys = UserDefaults.standard.dictionaryRepresentation().keys
        
        for key in userKeys {
            if key.hasPrefix("userData_") {
                if let userData = UserDefaults.standard.dictionary(forKey: key),
                   let isWeChatUser = userData["isWeChatUser"] as? Bool,
                   let wechatOpenId = userData["wechatOpenId"] as? String,
                   isWeChatUser && wechatOpenId == wechatUserInfo.openId {
                    
                    // 找到对应的用户数据
                    let phoneNumber = String(key.dropFirst("userData_".count))
                    loadUserData(from: userData, phoneNumber: phoneNumber)
                    
                    // 设置登录状态
                    isLoggedIn = true
                    
                    // 保存登录状态
                    UserDefaults.standard.set(phoneNumber, forKey: "lastLoggedInUser")
                    
                    print("微信用户登录成功: \(wechatUserInfo.nickname)")
                    return
                }
            }
        }
    }
    
    // 绑定微信用户
    func bindWeChatUser(phoneNumber: String, nickname: String, userType: String, birthDate: Date, wechatUserInfo: WeChatUserInfo) -> Bool {
        // 检查手机号是否已被使用
        if UserDefaults.standard.object(forKey: "userData_\(phoneNumber)") != nil {
            return false // 手机号已被使用
        }
        
        // 创建用户数据
        let userData: [String: Any] = [
            "nickname": nickname,
            "userType": userType,
            "birthDate": birthDate.timeIntervalSince1970,
            "isWeChatUser": true,
            "wechatOpenId": wechatUserInfo.openId,
            "wechatNickname": wechatUserInfo.nickname,
            "wechatAvatarUrl": wechatUserInfo.avatarUrl,
            "wechatUnionId": wechatUserInfo.unionId ?? ""
        ]
        
        // 保存用户数据
        UserDefaults.standard.set(userData, forKey: "userData_\(phoneNumber)")
        
        // 立即登录用户
        currentUser = UserData(
            nickname: nickname,
            phoneNumber: phoneNumber,
            userType: userType,
            birthDate: birthDate,
            isWeChatUser: true,
            wechatOpenId: wechatUserInfo.openId,
            wechatNickname: wechatUserInfo.nickname,
            wechatAvatarUrl: wechatUserInfo.avatarUrl
        )
        
        isLoggedIn = true
        UserDefaults.standard.set(phoneNumber, forKey: "lastLoggedInUser")
        
        print("微信用户绑定并登录成功")
        return true
    }
    
    // 测试服务器连接
    func testServerConnection(completion: @escaping (Bool, String) -> Void) {
        DatabaseConfig.shared.healthCheck { success, message in
            completion(success, message)
        }
    }
} 