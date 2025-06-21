//
//  HandLevelView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct HandLevelView: View {
    @State private var completedLevels: Set<Int> = [] // 只有第一关解锁，没有完成
    @Environment(\.dismiss) private var dismiss
    private let handColor = Color(red: 1.0, green: 0.706, blue: 0.694) // #ffb4b1
    
    var body: some View {
        ZStack {
            // 1. 米白色背景 - 确保完全覆盖整个屏幕
            Color(hex: "f5f5f0")
                .ignoresSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 2. level_background图片 - 延伸填充整个屏幕
            Image("level_background")
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(
                    minWidth: UIScreen.main.bounds.width * 1.5,
                    minHeight: UIScreen.main.bounds.height * 1.5
                )
                .opacity(0.25)
                .clipped()
                .ignoresSafeArea(.all)
            
            GeometryReader { geometry in
                ZStack {
                    // 3. 进一步缩小的游戏路径，第1关在底部
                    CurvePath(color: handColor)
                        .stroke(handColor, lineWidth: 6)
                        .shadow(color: handColor.opacity(0.4), radius: 8, x: 0, y: 3)
                    
                    // 4. 关卡按钮（第1关在底部，重新排序）
                    HandLevelButtonsView(
                        completedLevels: $completedLevels,
                        geometry: geometry,
                        color: handColor
                    )
                    
                    // 5. 礼品盒（带花型背景）
                    GiftBoxView(
                        position: getGiftPosition(in: geometry),
                        color: handColor
                    )
                }
            }
            
            // 6. 吉祥物 - 严格保证在左下角
            VStack {
                Spacer()
                HStack {
                    Image("mascot")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 280, height: 280)
                        .padding(.leading, 10)
                        .padding(.bottom, 20)
                    Spacer()
                }
            }
            
            // 7. TopBlurView - 顶部遮挡
            TopBlurView()
            
            // 8. 返回按钮 - 左上角，在TopBlurView之上
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 20)
                    .padding(.top, 50)
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
        .statusBarHidden(false)
        .preferredColorScheme(.light)
    }
}

// 手部关卡按钮视图（第1关在底部，重新排序）
struct HandLevelButtonsView: View {
    @Binding var completedLevels: Set<Int>
    let geometry: GeometryProxy
    let color: Color
    
    var body: some View {
        let positions = getLevelPositions(in: geometry)
        
        ForEach(1...8, id: \.self) { level in
            let position = positions[level - 1]
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
        
        let _ = withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            completedLevels.insert(level)
        }
    }
}

#Preview {
    HandLevelView()
} 