//
//  HandLevelView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct HandLevelView: View {
    @State private var completedLevels: Set<Int> = [1] // 默认第一关已解锁
    private let handColor = Color(red: 1.0, green: 0.706, blue: 0.694) // #ffb4b1
    
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
                    LevelCurvePath(color: handColor)
                        .stroke(handColor, lineWidth: 8)
                        .shadow(color: handColor.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    // 关卡按钮
                    HandLevelButtonsView(
                        completedLevels: $completedLevels,
                        geometry: geometry,
                        color: handColor
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

// 自定义S形曲线路径
struct LevelCurvePath: Shape {
    let color: Color
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // 起点
        path.move(to: CGPoint(x: width * 0.2, y: height * 0.1))
        
        // 创建S形曲线，参考curve.svg的扭曲效果
        path.addCurve(
            to: CGPoint(x: width * 0.8, y: height * 0.3),
            control1: CGPoint(x: width * 0.5, y: height * 0.05),
            control2: CGPoint(x: width * 0.9, y: height * 0.2)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.3, y: height * 0.5),
            control1: CGPoint(x: width * 0.7, y: height * 0.4),
            control2: CGPoint(x: width * 0.1, y: height * 0.45)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.85, y: height * 0.7),
            control1: CGPoint(x: width * 0.6, y: height * 0.55),
            control2: CGPoint(x: width * 0.95, y: height * 0.6)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.2, y: height * 0.9),
            control1: CGPoint(x: width * 0.7, y: height * 0.8),
            control2: CGPoint(x: width * 0.0, y: height * 0.85)
        )
        
        return path
    }
}

// 手部关卡按钮视图
struct HandLevelButtonsView: View {
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

// 关卡按钮
struct LevelButton: View {
    let level: Int
    let isUnlocked: Bool
    let isCompleted: Bool
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 按钮背景
                Circle()
                    .fill(buttonBackgroundColor)
                    .frame(width: 50, height: 50)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                
                // 按钮内容
                if isUnlocked {
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(level)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                } else {
                    Image("lock")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(!isUnlocked)
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
        .scaleEffect(isCompleted ? 1.1 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isCompleted)
    }
    
    private var buttonBackgroundColor: Color {
        if !isUnlocked {
            return Color.gray.opacity(0.6)
        } else if isCompleted {
            return color.opacity(0.9)
        } else {
            return color.opacity(0.7)
        }
    }
}

// 礼品盒视图
struct GiftBoxView: View {
    let geometry: GeometryProxy
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image("gift")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(isAnimating ? 5 : -5))
                    .animation(
                        Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
                Spacer()
            }
            .padding(.bottom, 20)
        }
    }
}

// 按钮按压效果扩展
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

struct PressEventsModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                if pressing {
                    onPress()
                } else {
                    onRelease()
                }
            }, perform: {})
    }
}

#Preview {
    HandLevelView()
} 