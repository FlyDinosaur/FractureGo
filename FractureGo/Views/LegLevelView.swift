//
//  LegLevelView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct LegLevelView: View {
    @State private var completedLevels: Set<Int> = [1] // 默认第一关已解锁
    private let legColor = Color(red: 0.624, green: 0.596, blue: 0.984) // #9f98fb
    
    var body: some View {
        ZStack {
            // 背景图片
            Image("level_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            
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
                    
                    // 吉祥物图片 - 右下角
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image("mascot")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .padding(.trailing, 20)
                                .padding(.bottom, 100) // 在底部导航栏之上
                        }
                    }
                    
                    // 礼品盒（所有关卡完成后显示）
                    if completedLevels.count >= 8 {
                        GiftBoxView(geometry: geometry)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            .padding(.bottom, 50)
            
            // 顶部遮挡视图
            TopBlurView()
        }
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
            CGPoint(x: width * 0.2, y: height * 0.1),   // 关卡1
            CGPoint(x: width * 0.65, y: height * 0.25),  // 关卡2
            CGPoint(x: width * 0.8, y: height * 0.3),   // 关卡3
            CGPoint(x: width * 0.4, y: height * 0.45),  // 关卡4
            CGPoint(x: width * 0.3, y: height * 0.5),   // 关卡5
            CGPoint(x: width * 0.7, y: height * 0.65),  // 关卡6
            CGPoint(x: width * 0.85, y: height * 0.7),  // 关卡7
            CGPoint(x: width * 0.2, y: height * 0.9)    // 关卡8
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
        if level == 1 { return true }
        return completedLevels.contains(level - 1)
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