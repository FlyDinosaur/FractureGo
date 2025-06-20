//
//  LevelComponents.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

// MARK: - 自定义S形曲线路径
struct LevelCurvePath: Shape {
    let color: Color
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // 起点 - 修正为从屏幕边缘开始
        path.move(to: CGPoint(x: width * 0.15, y: height * 0.15))
        
        // 创建S形曲线，覆盖整个屏幕区域
        path.addCurve(
            to: CGPoint(x: width * 0.85, y: height * 0.32),
            control1: CGPoint(x: width * 0.5, y: height * 0.05),
            control2: CGPoint(x: width * 0.9, y: height * 0.22)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.25, y: height * 0.55),
            control1: CGPoint(x: width * 0.8, y: height * 0.42),
            control2: CGPoint(x: width * 0.1, y: height * 0.45)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.85, y: height * 0.78),
            control1: CGPoint(x: width * 0.6, y: height * 0.65),
            control2: CGPoint(x: width * 0.95, y: height * 0.68)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.15, y: height * 0.88),
            control1: CGPoint(x: width * 0.7, y: height * 0.88),
            control2: CGPoint(x: width * 0.0, y: height * 0.85)
        )
        
        return path
    }
}

// MARK: - 关卡按钮
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
            // 未完成但已解锁的关卡使用更亮的颜色
            return color.opacity(0.85)
        }
    }
}

// MARK: - 礼品盒视图
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

 