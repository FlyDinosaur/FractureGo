//
//  SplashView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.8
    @State private var showLogin = false
    @State private var animationPhase = 0 // 0: 渐入, 1: 停留, 2: 淡出, 3: 显示登录界面
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            if !showLogin {
                // 开屏内容
                VStack(spacing: 30) {
                    // Logo Icon
                    Image("icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)
                        .opacity(opacity)
                    
                    // App Name
                    Text("FractureGo")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.black)
                        .opacity(opacity)
                }
                .animation(.easeInOut(duration: 1.0), value: animationPhase)
            }
        }
        .onAppear {
            startAnimation()
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
        }
    }
    
    private func startAnimation() {
        // 第一阶段：渐入动画
        animationPhase = 0
        withAnimation(.easeInOut(duration: 1.0)) {
            opacity = 1.0
            scale = 1.0
        }
        
        // 第二阶段：停留
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // 第三阶段：淡出
            animationPhase = 2
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 0.0
            }
            
            // 第四阶段：显示登录界面
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showLogin = true
            }
        }
    }
}

#Preview {
    SplashView()
} 