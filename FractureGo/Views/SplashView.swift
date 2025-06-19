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
    @State private var offsetY: CGFloat = 0
    @State private var showLogin = false
    @State private var animationPhase = 0 // 0: 渐入, 1: 停留, 2: 移动到登录位置
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo Icon
                Image("icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: animationPhase == 2 ? 80 : 120, 
                           height: animationPhase == 2 ? 80 : 120)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .offset(y: offsetY)
                
                // App Name
                Text("FractureGo")
                    .font(.system(size: animationPhase == 2 ? 24 : 32, 
                                weight: .light, design: .default))
                    .foregroundColor(.black)
                    .opacity(opacity)
                    .offset(y: offsetY)
            }
            .offset(y: animationPhase == 2 ? -200 : 0)
        }
        .onAppear {
            startAnimationSequence()
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
        }
    }
    
    private func startAnimationSequence() {
        // 阶段1: 渐入动画
        withAnimation(.easeIn(duration: 1.0)) {
            opacity = 1.0
            scale = 1.0
            animationPhase = 1
        }
        
        // 阶段2: 停留3秒
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // 阶段3: 移动到登录界面位置
            withAnimation(.easeInOut(duration: 1.0)) {
                animationPhase = 2
                offsetY = -100
            }
            
            // 显示登录界面
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showLogin = true
            }
        }
    }
}

#Preview {
    SplashView()
} 