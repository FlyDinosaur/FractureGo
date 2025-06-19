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
    
    var body: some View {
        ZStack {
            // 背景
            Color.white.ignoresSafeArea()
            
            // 顶部波浪遮挡
            TopBlurView()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo和标题
                VStack(spacing: 20) {
                    Image("icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                    
                    Text("FractureGo")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.black)
                }
                .padding(.top, 100)
                
                Spacer()
                
                // 登录按钮组
                VStack(spacing: 20) {
                    // 微信登录按钮
                    Button(action: {
                        handleWeChatLogin()
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundColor(.white)
                            Text("微信登录")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "9ecd57"))
                        .cornerRadius(25)
                    }
                    .padding(.horizontal, 40)
                    
                    // 账号密码登录按钮
                    Button(action: {
                        showAccountLogin = true
                    }) {
                        Text("账号密码登录")
                            .foregroundColor(Color(hex: "9ecd57"))
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color(hex: "9ecd57"), lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                    .frame(height: 80)
            }
        }
        .fullScreenCover(isPresented: $showAccountLogin) {
            AccountLoginView()
        }
        .fullScreenCover(isPresented: $showWeChatBinding) {
            WeChatBindingView()
        }
    }
    
    private func handleWeChatLogin() {
        // 这里实现微信登录逻辑
        // 暂时直接跳转到绑定界面模拟首次登录
        showWeChatBinding = true
    }
}

#Preview {
    LoginView()
} 