//
//  LegLevelView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct LegLevelView: View {
    @State private var currentLevel = 1 // 当前解锁关卡
    @State private var completedLevels: Set<Int> = [1] // 已完成的关卡
    @Environment(\.presentationMode) var presentationMode
    
    private let themeColor = Color(hex: "9f98fb") // 腿部恢复主题色
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
                    LegLevelButtonsView(
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

// MARK: - 腿部关卡按钮视图
struct LegLevelButtonsView: View {
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
                        playLegLevel(level)
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
    
    private func playLegLevel(_ level: Int) {
        // 这里实现腿部训练关卡游戏逻辑
        print("开始腿部训练第 \(level) 关")
        
        // 模拟通关
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completedLevels.insert(level)
            if level < totalLevels {
                currentLevel = max(currentLevel, level + 1)
            }
        }
    }
}

#Preview {
    LegLevelView()
} 