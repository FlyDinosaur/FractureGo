//
//  HandLevelView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct HandLevelView: View {
    @State private var currentLevel = 1 // 当前解锁关卡
    @State private var completedLevels: Set<Int> = [1] // 已完成的关卡
    @Environment(\.presentationMode) var presentationMode
    
    private let themeColor = Color(hex: "ffb4b1") // 手部恢复主题色
    private let totalLevels = 8
    
    var body: some View {
        ZStack {
            // 背景图片
            Image("level_background")
                .resizable()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部模糊视图
                TopBlurView()
                
                Spacer()
                
                // 关卡内容
                ZStack {
                    // 曲线路径
                    LevelCurvePath(themeColor: themeColor, totalLevels: totalLevels)
                    
                    // 关卡按钮
                    LevelButtonsView(
                        currentLevel: $currentLevel,
                        completedLevels: $completedLevels,
                        themeColor: themeColor,
                        totalLevels: totalLevels
                    )
                    
                    // 左下角吉祥物
                    VStack {
                        Spacer()
                        HStack {
                            Image("mascot")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 100)
                                .padding(.leading, 20)
                                .padding(.bottom, 100) // 导航栏上方
                            Spacer()
                        }
                    }
                    
                    // 礼品盒（在最后）
                    if completedLevels.count == totalLevels {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                GiftBoxView()
                                    .padding(.trailing, 40)
                                    .padding(.bottom, 200)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 底部导航栏
                BottomNavigationView()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - 曲线路径视图
struct LevelCurvePath: View {
    let themeColor: Color
    let totalLevels: Int
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let levelSpacing = height / CGFloat(totalLevels + 1)
                
                // 起始点
                let startPoint = CGPoint(x: width * 0.1, y: height * 0.1)
                path.move(to: startPoint)
                
                // 创建S形曲线路径
                for i in 1...totalLevels {
                    let y = levelSpacing * CGFloat(i)
                    let x = i % 2 == 1 ? width * 0.8 : width * 0.2
                    
                    let controlPoint1 = CGPoint(
                        x: width * (i % 2 == 1 ? 0.3 : 0.7),
                        y: y - levelSpacing * 0.3
                    )
                    let controlPoint2 = CGPoint(
                        x: width * (i % 2 == 1 ? 0.6 : 0.4),
                        y: y - levelSpacing * 0.1
                    )
                    let endPoint = CGPoint(x: x, y: y)
                    
                    path.addCurve(to: endPoint, control1: controlPoint1, control2: controlPoint2)
                }
            }
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [themeColor.opacity(0.3), themeColor]),
                    startPoint: .top,
                    endPoint: .bottom
                ),
                style: StrokeStyle(lineWidth: 6, lineCap: .round)
            )
        }
    }
}

// MARK: - 关卡按钮视图
struct LevelButtonsView: View {
    @Binding var currentLevel: Int
    @Binding var completedLevels: Set<Int>
    let themeColor: Color
    let totalLevels: Int
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(1...totalLevels, id: \.self) { level in
                LevelButton(
                    level: level,
                    isUnlocked: level <= currentLevel,
                    isCompleted: completedLevels.contains(level),
                    themeColor: themeColor,
                    position: calculatePosition(for: level, in: geometry)
                ) {
                    // 关卡点击处理
                    if level <= currentLevel {
                        playLevel(level)
                    }
                }
            }
        }
    }
    
    private func calculatePosition(for level: Int, in geometry: GeometryProxy) -> CGPoint {
        let width = geometry.size.width
        let height = geometry.size.height
        let levelSpacing = height / CGFloat(totalLevels + 1)
        
        let y = levelSpacing * CGFloat(level)
        let x = level % 2 == 1 ? width * 0.8 : width * 0.2
        
        return CGPoint(x: x, y: y)
    }
    
    private func playLevel(_ level: Int) {
        // 这里实现关卡游戏逻辑
        print("开始第 \(level) 关")
        
        // 模拟通关
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completedLevels.insert(level)
            if level < totalLevels {
                currentLevel = max(currentLevel, level + 1)
            }
        }
    }
}

// MARK: - 单个关卡按钮
struct LevelButton: View {
    let level: Int
    let isUnlocked: Bool
    let isCompleted: Bool
    let themeColor: Color
    let position: CGPoint
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 按钮背景
                Circle()
                    .fill(
                        isUnlocked ?
                        LinearGradient(
                            gradient: Gradient(colors: [themeColor.opacity(0.8), themeColor]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: themeColor.opacity(0.3), radius: isUnlocked ? 8 : 2)
                
                // 图标或数字
                if isUnlocked {
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Text("\(level)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                } else {
                    Image("lock")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(themeColor)
                }
            }
        }
        .position(position)
        .disabled(!isUnlocked)
        .scaleEffect(isCompleted ? 1.1 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isCompleted)
    }
}

// MARK: - 礼品盒视图
struct GiftBoxView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: {
            // 打开礼品盒
            print("打开礼品盒")
        }) {
            Image("gift")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .rotationEffect(.degrees(isAnimating ? 5 : -5))
                .animation(
                    Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - 底部导航栏视图
struct BottomNavigationView: View {
    var body: some View {
        HStack {
            NavigationBarButton(icon: "home_icon", label: "首页")
            Spacer()
            NavigationBarButton(icon: "checkmark.circle", label: "训练")
            Spacer()
            NavigationBarButton(icon: "Share_icon", label: "分享")
            Spacer()
            NavigationBarButton(icon: "message", label: "消息")
            Spacer()
            NavigationBarButton(icon: "my_icon", label: "我的")
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.9))
        .cornerRadius(25)
        .padding(.horizontal, 20)
        .padding(.bottom, 35)
    }
}

struct NavigationBarButton: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon.contains("_") ? "house" : icon)
                .font(.system(size: 20))
                .foregroundColor(.gray)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    HandLevelView()
} 