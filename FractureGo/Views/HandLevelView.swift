//
//  HandLevelView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct HandLevelView: View {
    @State private var completedLevels: Set<Int> = [] // 只有第一关解锁，没有完成
    private let handColor = Color(red: 1.0, green: 0.706, blue: 0.694) // #ffb4b1
    
    var body: some View {
        ZStack {
            // 1. 最底层：米白色背景确保不是黑色
            Color(hex: "f5f5f0")
                .ignoresSafeArea(.all)
            
            // 2. level_background背景图片 - 完全填充屏幕
            Image("level_background")
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
                .clipped()
            
            // 3. 关卡内容层 - 占据整个屏幕
            GeometryReader { geometry in
                ZStack {
                    // S形曲线路径
                    LevelCurvePath(color: handColor)
                        .stroke(handColor, lineWidth: 8)
                        .shadow(color: handColor.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    // 关卡按钮
                    HandLevelButtonsView(
                        completedLevels: $completedLevels,
                        geometry: geometry,
                        color: handColor
                    )
                    
                    // 吉祥物图片 - 左下角，放大3倍
                    VStack {
                        Spacer()
                        HStack {
                            Image("mascot")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 300, height: 300) // 从100放大到300 (3倍)
                                .padding(.leading, 20)
                                .padding(.bottom, 100) // 减少底部间距
                            Spacer()
                        }
                    }
                    
                    // 礼品盒 - 显示在右下角，靠近底部
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image("gift")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .padding(.trailing, 20)
                                .padding(.bottom, 120) // 减少底部间距，让gift更靠近底部
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

// 手部关卡按钮视图
struct HandLevelButtonsView: View {
    @Binding var completedLevels: Set<Int>
    let geometry: GeometryProxy
    let color: Color
    
    // 8个关卡的位置，沿着S形曲线分布 - 修正坐标让关卡1在顶部
    private var levelPositions: [CGPoint] {
        let width = geometry.size.width
        let height = geometry.size.height
        
        return [
            CGPoint(x: width * 0.15, y: height * 0.08),   // 关卡1 - 顶部起点
            CGPoint(x: width * 0.45, y: height * 0.12),   // 关卡2 - 第一段曲线上
            CGPoint(x: width * 0.75, y: height * 0.18),   // 关卡3 - 第一段曲线末端
            CGPoint(x: width * 0.85, y: height * 0.28),   // 关卡4 - 转折点
            CGPoint(x: width * 0.55, y: height * 0.42),   // 关卡5 - 第二段曲线中
            CGPoint(x: width * 0.25, y: height * 0.55),   // 关卡6 - 第二段曲线末端
            CGPoint(x: width * 0.55, y: height * 0.68),   // 关卡7 - 第三段曲线中
            CGPoint(x: width * 0.85, y: height * 0.82),   // 关卡8 - 底部末端
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
    HandLevelView()
} 