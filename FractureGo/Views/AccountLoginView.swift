//
//  AccountLoginView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI
import CryptoKit

struct AccountLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var isAutoLogin = false
    @State private var showRegister = false
    @State private var showMainView = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // 背景
            Color(hex: "f5f5f0").ignoresSafeArea()
            
            // 顶部波浪遮挡
            TopBlurView()
            
            VStack(spacing: 30) {
                // 返回按钮
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 登录表单
                VStack(spacing: 25) {
                    Text("账号登录")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    
                    VStack(spacing: 15) {
                        // 手机号输入框
                        HStack {
                            Image(systemName: "phone")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            TextField("手机号", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        // 密码输入框
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            SecureField("密码", text: $password)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        // 自动登录和忘记密码
                        HStack {
                            Button(action: {
                                isAutoLogin.toggle()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: isAutoLogin ? "checkmark.square" : "square")
                                        .foregroundColor(Color(hex: "9ecd57"))
                                    Text("自动登录")
                                        .font(.system(size: 14))
                                        .foregroundColor(.black)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // 忘记密码逻辑
                                alertMessage = "请联系客服重置密码"
                                showAlert = true
                            }) {
                                Text("忘记密码？")
                                    .font(.system(size: 14))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // 登录按钮
                    Button(action: {
                        loginUser()
                    }) {
                        Text("登录")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "9ecd57"))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 30)
                    .disabled(phoneNumber.isEmpty || password.isEmpty)
                    .opacity(phoneNumber.isEmpty || password.isEmpty ? 0.6 : 1.0)
                    
                    // 注册按钮
                    Button(action: {
                        showRegister = true
                    }) {
                        Text("注册")
                            .font(.headline)
                            .foregroundColor(Color(hex: "9ecd57"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "9ecd57"), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 30)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .alert("提示", isPresented: $showAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
        .fullScreenCover(isPresented: $showMainView) {
            MainView()
        }
        .onAppear {
            loadSavedCredentials()
        }
    }
    
    private func loginUser() {
        // 验证输入
        guard !phoneNumber.isEmpty && !password.isEmpty else {
            alertMessage = "请输入手机号和密码"
            showAlert = true
            return
        }
        
        // 获取用户数据
        guard let userData = UserDefaults.standard.dictionary(forKey: "userData_\(phoneNumber)") else {
            alertMessage = "用户不存在，请先注册"
            showAlert = true
            return
        }
        
        // 验证密码
        let encryptedPassword = md5Hash(password)
        guard let savedPassword = userData["password"] as? String,
              savedPassword == encryptedPassword else {
            alertMessage = "密码错误"
            showAlert = true
            return
        }
        
        // 保存自动登录状态
        if isAutoLogin {
            UserDefaults.standard.set(true, forKey: "isAutoLogin")
            UserDefaults.standard.set(phoneNumber, forKey: "savedPhoneNumber")
        } else {
            UserDefaults.standard.removeObject(forKey: "isAutoLogin")
            UserDefaults.standard.removeObject(forKey: "savedPhoneNumber")
        }
        
        // 登录成功
        UserManager.shared.loginUser(phoneNumber: phoneNumber, userData: userData)
        showMainView = true
    }
    
    private func loadSavedCredentials() {
        if let savedPhoneNumber = UserDefaults.standard.string(forKey: "savedPhoneNumber") {
            phoneNumber = savedPhoneNumber
            isAutoLogin = UserDefaults.standard.bool(forKey: "isAutoLogin")
        }
    }
    
    private func md5Hash(_ string: String) -> String {
        let digest = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

#Preview {
    AccountLoginView()
} 