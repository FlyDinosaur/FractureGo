//
//  AccountLoginView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI
import CryptoKit

struct AccountLoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var savePassword = UserManager.shared.savePassword
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showMainView = false
    @State private var showRegister = false
    
    var body: some View {
        ZStack {
            // 背景
            Color(hex: "f5f5f0").ignoresSafeArea()
            
            // 顶部波浪遮挡
            TopBlurView()
            
            VStack(spacing: 20) {
                // 返回按钮
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color(hex: "9ecd57")) // 绿色，背景为白色的反色
                    }
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                Spacer()
                    .frame(height: 20)
                
                // 登录表单
                VStack(spacing: 25) {
                    Text("账号密码登录")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    
                    VStack(spacing: 15) {
                        // 手机号输入框
                        HStack {
                            Image(systemName: "phone")
                                .foregroundColor(.black.opacity(0.7))
                                .frame(width: 20)
                            TextField("", text: $phoneNumber, prompt: Text("手机号").foregroundColor(.black.opacity(0.6)))
                                .keyboardType(.phonePad)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.black)
                                .onChange(of: phoneNumber) { newValue in
                                    // 当手机号改变时，自动填充保存的密码
                                    if let savedPassword = UserManager.shared.getSavedPassword(for: newValue) {
                                        password = savedPassword
                                    } else {
                                        password = ""
                                    }
                                }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                        
                        // 密码输入框
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.black.opacity(0.7))
                                .frame(width: 20)
                            SecureField("", text: $password, prompt: Text("密码").foregroundColor(.black.opacity(0.6)))
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                        
                        // 功能选项
                        HStack {
                            Button(action: {
                                savePassword.toggle()
                                UserManager.shared.savePassword = savePassword
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: savePassword ? "checkmark.square.fill" : "square")
                                        .foregroundColor(savePassword ? Color(hex: "9ecd57") : .black.opacity(0.3))
                                    Text("保存密码")
                                        .font(.system(size: 14))
                                        .foregroundColor(.black.opacity(0.8))
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
                                    .foregroundColor(.black.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 5)
                    }
                    .padding(.horizontal, 30)
                    
                    // 登录按钮
                    Button(action: {
                        loginWithAccount()
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
                    
                    // 注册按钮 - 改为Button + fullScreenCover
                    Button(action: {
                        print("注册按钮被点击 - AccountLoginView") // 添加调试信息
                        showRegister = true
                    }) {
                        Text("注册")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "9ecd57"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "9ecd57"), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 30)
                }
                
                Spacer()
                    .frame(height: 60)
            }
        }
        .navigationBarHidden(true)
        .onTapGesture {
            // 点击空白区域隐藏键盘
            hideKeyboard()
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
        .fullScreenCover(isPresented: $showMainView) {
            MainView()
        }
        .fullScreenCover(isPresented: $showRegister) {
            RegisterView()
        }
        .onAppear {
            // 自动填充保存的手机号和密码
            if let savedPhone = UserManager.shared.getSavedPhoneNumber() {
                phoneNumber = savedPhone
                if let savedPassword = UserManager.shared.getSavedPassword(for: savedPhone) {
                    password = savedPassword
                }
            }
        }
    }
    
    private func loginWithAccount() {
        // 验证手机号格式
        if !isValidPhoneNumber(phoneNumber) {
            alertMessage = "请输入正确的手机号"
            showAlert = true
            return
        }
        
        // 验证密码长度
        if password.count < 6 {
            alertMessage = "密码长度不能少于6位"
            showAlert = true
            return
        }
        
        // MD5加密密码
        let hashedPassword = password.md5
        
        // 模拟登录验证
        if UserManager.shared.validateLogin(phone: phoneNumber, password: hashedPassword) {
            // 登录成功
            UserManager.shared.saveUserSession(
                phone: phoneNumber,
                password: password, // 保存原始密码，用于自动填充
                savePassword: savePassword
            )
            
            showMainView = true
        } else {
            alertMessage = "手机号或密码错误"
            showAlert = true
        }
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = "^1[3-9]\\d{9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
}

#Preview {
    AccountLoginView()
} 