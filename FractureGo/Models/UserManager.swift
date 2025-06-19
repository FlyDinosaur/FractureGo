//
//  UserManager.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import Foundation
import SwiftUI

class UserManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: UserData?
    
    struct UserData {
        let nickname: String
        let phoneNumber: String
        let userType: String
        let birthDate: Date
        let isWeChatUser: Bool
    }
    
    init() {
        checkAutoLogin()
    }
    
    func checkAutoLogin() {
        let isAutoLogin = UserDefaults.standard.bool(forKey: "isAutoLogin")
        if isAutoLogin, let phoneNumber = UserDefaults.standard.string(forKey: "savedPhoneNumber") {
            if let userData = UserDefaults.standard.dictionary(forKey: "userData_\(phoneNumber)") {
                loadUserData(from: userData)
                isLoggedIn = true
            }
        }
    }
    
    func login(phoneNumber: String, password: String, autoLogin: Bool = false) -> Bool {
        // 验证用户凭据
        if let userData = UserDefaults.standard.dictionary(forKey: "userData_\(phoneNumber)") {
            if let savedPassword = userData["password"] as? String,
               savedPassword == password.md5 {
                
                if autoLogin {
                    UserDefaults.standard.set(true, forKey: "isAutoLogin")
                    UserDefaults.standard.set(phoneNumber, forKey: "savedPhoneNumber")
                }
                
                loadUserData(from: userData)
                isLoggedIn = true
                return true
            }
        }
        return false
    }
    
    func logout() {
        isLoggedIn = false
        currentUser = nil
        UserDefaults.standard.set(false, forKey: "isAutoLogin")
        UserDefaults.standard.removeObject(forKey: "savedPhoneNumber")
    }
    
    private func loadUserData(from data: [String: Any]) {
        guard let nickname = data["nickname"] as? String,
              let phoneNumber = data["phoneNumber"] as? String,
              let userType = data["userType"] as? String,
              let birthDate = data["birthDate"] as? Date else { return }
        
        let isWeChatUser = data["isWeChatUser"] as? Bool ?? false
        
        currentUser = UserData(
            nickname: nickname,
            phoneNumber: phoneNumber,
            userType: userType,
            birthDate: birthDate,
            isWeChatUser: isWeChatUser
        )
    }
} 