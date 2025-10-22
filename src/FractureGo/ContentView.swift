//
//  ContentView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/17.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @ObservedObject private var userManager = UserManager.shared
    @State private var showSplash = true
    
    var body: some View {
        Group {
            if showSplash {
                SplashView()
            } else if userManager.isLoggedIn {
                MainView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            // 监听微信登录成功通知
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("WeChatLoginSuccess"),
                object: nil,
                queue: .main
            ) { _ in
                // 微信登录成功，更新界面
                print("收到微信登录成功通知")
            }
            
            // 设置开屏延迟
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
        .onDisappear {
            // 移除通知监听
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("WeChatLoginSuccess"), object: nil)
        }
    }
}

#Preview {
    ContentView()
}
