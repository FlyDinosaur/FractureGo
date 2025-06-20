//
//  LoginView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct LoginView: View {
    @State private var showAccountLogin = false
    @State private var showWeChatBinding = false
    @State private var isWeChatLogging = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @ObservedObject private var wechatManager = WeChatManager.shared
    @ObservedObject private var userManager = UserManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color.white.ignoresSafeArea()
                
                // 顶部波浪遮挡
                TopBlurView()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo和标题 - 居中显示
                    VStack(spacing: 20) {
                        Image("icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                        
                        Text("FractureGo")
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    // 登录按钮区域 - 居中靠上
                    VStack(spacing: 20) {
                        // 微信登录按钮
                        Button(action: {
                            // 显示暂未支持提示
                            alertMessage = "微信登录功能暂未支持，请使用账号密码登录"
                            showAlert = true
                        }) {
                            HStack {
                                if isWeChatLogging {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("连接中...")
                                        .foregroundColor(.white)
                                } else {
                                    Text("微信登录")
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color(hex: "9ecd57"))
                            .cornerRadius(25)
                        }
                        .padding(.horizontal, 40)
                        
                        // 账号密码登录按钮
                        Button(action: {
                            showAccountLogin = true
                        }) {
                            Text("账号密码登录")
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.white)
                                .cornerRadius(25)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
            }
            .onTapGesture {
                // 点击空白区域隐藏键盘
                hideKeyboard()
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showAccountLogin) {
            AccountLoginView()
        }
        .fullScreenCover(isPresented: $showWeChatBinding) {
            WeChatBindingView(wechatUserInfo: WeChatUserInfo(
                openId: "temp_openid",
                nickname: "临时用户",
                avatarUrl: "",
                unionId: nil
            ))
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // 测试服务器连接
            userManager.testServerConnection { success, message in
                DispatchQueue.main.async {
                    if !success {
                        print("⚠️ 服务器连接测试失败: \(message)")
                        // 不再自动显示错误弹窗，用户在登录时会得到具体的错误信息
                    } else {
                        print("✅ 服务器连接测试成功: \(message)")
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
} 