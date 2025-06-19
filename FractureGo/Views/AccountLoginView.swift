//
//  AccountLoginView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct AccountLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var isAutoLogin = false
    @State private var showRegister = false
    @State private var showMainView = false
    
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
                            .foregroundColor(.white)
                            .font(.title2)
                            .padding()
                    }
                    Spacer()
                }
                .padding(.top, 50)
                
                Spacer()
                
                // 登录标题
                Text("登录")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(Color(hex: "9ecd57"))
                    .padding(.bottom, 20)
                
                // 输入框容器
                VStack(spacing: 20) {
                    // 手机号输入框
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("手机号码", text: $phoneNumber)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                                .keyboardType(.phonePad)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(25)
                    }
                    
                    // 密码输入框
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            SecureField("密码", text: $password)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 30)
                
                // 自动登录和忘记密码
                HStack {
                    // 自动登录选择框
                    Button(action: {
                        isAutoLogin.toggle()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isAutoLogin ? "checkmark.square.fill" : "square")
                                .foregroundColor(Color(hex: "9ecd57"))
                                .font(.title3)
                            Text("自动登录")
                                .foregroundColor(Color(hex: "9ecd57"))
                                .font(.system(size: 14))
                        }
                    }
                    
                    Spacer()
                    
                    // 忘记密码
                    Button(action: {
                        // 处理忘记密码
                    }) {
                        Text("忘记密码?")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // 按钮组
                VStack(spacing: 15) {
                    // 登录按钮
                    Button(action: {
                        handleLogin()
                    }) {
                        Text("登录")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(hex: "9ecd57"))
                            .cornerRadius(25)
                    }
                    .padding(.horizontal, 30)
                    
                    // 或者分隔线
                    Text("或者")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    
                    // 注册按钮
                    Button(action: {
                        showRegister = true
                    }) {
                        Text("注册")
                            .foregroundColor(Color(hex: "9ecd57"))
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color(hex: "9ecd57"), lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 30)
                }
                
                Spacer()
                    .frame(height: 60)
            }
        }
        .fullScreenCover(isPresented: $showRegister) {
            RegisterView()
        }
        .fullScreenCover(isPresented: $showMainView) {
            MainView()
        }
    }
    
    private func handleLogin() {
        // 这里实现登录逻辑
        // 验证手机号和密码
        if !phoneNumber.isEmpty && !password.isEmpty {
            // 模拟登录成功
            if isAutoLogin {
                // 保存自动登录信息
                UserDefaults.standard.set(true, forKey: "isAutoLogin")
                UserDefaults.standard.set(phoneNumber, forKey: "savedPhoneNumber")
            }
            showMainView = true
        }
    }
}

#Preview {
    AccountLoginView()
} 