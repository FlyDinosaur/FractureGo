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
    
    struct UserData {
        let nickname: String
        let phoneNumber: String
        let userType: String
        let birthDate: Date
        let isWeChatUser: Bool
    }
    
    private init() {
        checkAutoLogin()
    }
    
    func checkAutoLogin() {
        let isAutoLogin = UserDefaults.standard.bool(forKey: "isAutoLogin")
        if isAutoLogin, let phoneNumber = UserDefaults.standard.string(forKey: "savedPhoneNumber") {
            if let userData = UserDefaults.standard.dictionary(forKey: "userData_\(phoneNumber)") {
                loadUserData(from: userData, phoneNumber: phoneNumber)
                isLoggedIn = true
            }
        }
    }
    
    func loginUser(phoneNumber: String, userData: [String: Any]) {
        loadUserData(from: userData, phoneNumber: phoneNumber)
        isLoggedIn = true
    }
    
    private func loadUserData(from userData: [String: Any], phoneNumber: String) {
        guard let nickname = userData["nickname"] as? String,
              let userType = userData["userType"] as? String,
              let birthDateTimestamp = userData["birthDate"] as? TimeInterval,
              let isWeChatUser = userData["isWeChatUser"] as? Bool else {
            return
        }
        
        let birthDate = Date(timeIntervalSince1970: birthDateTimestamp)
        
        currentUser = UserData(
            nickname: nickname,
            phoneNumber: phoneNumber,
            userType: userType,
            birthDate: birthDate,
            isWeChatUser: isWeChatUser
        )
    }
    
    func logout() {
        isLoggedIn = false
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "isAutoLogin")
        UserDefaults.standard.removeObject(forKey: "savedPhoneNumber")
    }
} 