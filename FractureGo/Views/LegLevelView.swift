//
//  LegLevelView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct LegLevelView: View {
    @State private var completedLevels: Set<Int> = [] // 只有第一关解锁，没有完成
    private let legColor = Color(red: 0.624, green: 0.596, blue: 0.984) // #9f98fb
    
    var body: some View {
        ZStack {
            // 1. 最底层：米白色背景确保不是黑色
            Color(hex: "f5f5f0")
                .ignoresSafeArea(.all)
            
            // 2. level_background背景图片
            Image("level_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
            
            // 3. 关卡内容层 - 占据整个屏幕
            GeometryReader { geometry in
                ZStack {
                    // S形曲线路径
                    LevelCurvePath(color: legColor)
                        .stroke(legColor, lineWidth: 8)
                        .shadow(color: legColor.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    // 关卡按钮
                    LegLevelButtonsView(
                        completedLevels: $completedLevels,
                        geometry: geometry,
                        color: legColor
                    )
                    
                    // 吉祥物图片 - 左下角，放大3倍
                    VStack {
                        Spacer()
                        HStack {
                            Image("mascot")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 300, height: 300) // 从100放大到300 (3倍)
                                .padding(.leading, 30)
                                .padding(.bottom, 120)
                            Spacer()
                        }
                    }
                    
                    // 礼品盒 - 一开始就显示在右下角
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image("gift")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .padding(.trailing, 30)
                                .padding(.bottom, 140)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // 确保占据整个屏幕
            .ignoresSafeArea(.all) // 忽略所有安全区域
        }
        .navigationBarHidden(true)
        .background(Color(hex: "f5f5f0")) // 额外的背景保证
    }
}

// 腿部关卡按钮视图
struct LegLevelButtonsView: View {
    @Binding var completedLevels: Set<Int>
    let geometry: GeometryProxy
    let color: Color
    
    // 8个关卡的位置，沿着S形曲线分布
    private var levelPositions: [CGPoint] {
        let width = geometry.size.width
        let height = geometry.size.height
        
        return [
            CGPoint(x: width * 0.15, y: height * 0.15),   // 关卡1 - 曲线起点
            CGPoint(x: width * 0.45, y: height * 0.18),   // 关卡2 - 第一段曲线上
            CGPoint(x: width * 0.75, y: height * 0.25),   // 关卡3 - 第一段曲线末端
            CGPoint(x: width * 0.85, y: height * 0.32),   // 关卡4 - 转折点
            CGPoint(x: width * 0.55, y: height * 0.45),   // 关卡5 - 第二段曲线中
            CGPoint(x: width * 0.25, y: height * 0.55),   // 关卡6 - 第二段曲线末端
            CGPoint(x: width * 0.55, y: height * 0.68),   // 关卡7 - 第三段曲线中
            CGPoint(x: width * 0.85, y: height * 0.78),   // 关卡8 - 第三段曲线末端
        ]
    }
    
    var body: some View {
        ForEach(1...8, id: \.self) { level in
            let position = levelPositions[level - 1]
            let isUnlocked = isLevelUnlocked(level)
            let isCompleted = completedLevels.contains(level)
            
            LevelButton(
                level: level,
                isUnlocked: isUnlocked,
                isCompleted: isCompleted,
                color: color
            ) {
                handleLevelTap(level)
            }
            .position(position)
        }
    }
    
    private func isLevelUnlocked(_ level: Int) -> Bool {
        if level == 1 { return true } // 第一关默认解锁
        return completedLevels.contains(level - 1) // 前一关完成才能解锁下一关
    }
    
    private func handleLevelTap(_ level: Int) {
        guard isLevelUnlocked(level) else { return }
        
        // 模拟训练完成
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            completedLevels.insert(level)
        }
    }
}

#Preview {
    LegLevelView()
} 