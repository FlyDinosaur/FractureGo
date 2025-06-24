//
//  TopBlurView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct TopBlurView: View {
    var body: some View {
        // 使用ZStack确保背景透明
        ZStack {
            // 完全透明的背景
            Color.clear
            
            // 只显示绿色波浪形状
            VStack {
                WaveShape()
                    .fill(Color(hex: "9ecd57"))
                    .frame(height: 160)
                    .clipped()
                Spacer()
            }
        }
        .ignoresSafeArea(edges: .top) // 只忽略顶部安全区域
    }
}

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // 开始点 - 左上角
        path.move(to: CGPoint(x: 0, y: 0))
        
        // 顶部边缘 - 添加圆角  
        let topCornerRadius: CGFloat = 25
        path.addLine(to: CGPoint(x: width - topCornerRadius, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: width, y: topCornerRadius),
            control: CGPoint(x: width, y: 0)
        )
        
        // 右边缘到波浪开始位置
        path.addLine(to: CGPoint(x: width, y: height * 0.55))
        
        // 两段波浪形底边
        // 第一段：较大的波浪（向下凸起）
        path.addCurve(
            to: CGPoint(x: width * 0.7, y: height * 0.75),
            control1: CGPoint(x: width * 0.85, y: height * 0.95),
            control2: CGPoint(x: width * 0.8, y: height * 0.95)
        )
        
        // 中间的凹弧形过渡
        path.addCurve(
            to: CGPoint(x: width * 0.4, y: height * 0.75),
            control1: CGPoint(x: width * 0.6, y: height * 0.6),
            control2: CGPoint(x: width * 0.5, y: height * 0.6)
        )
        
        // 第二段：稍小的波浪（向下凸起）
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.55),
            control1: CGPoint(x: width * 0.3, y: height * 1.0),
            control2: CGPoint(x: width * 0.15, y: height * 1.0)
        )
        
        return path
    }
}

#Preview {
    ZStack {
        // 预览时显示背景色以便查看效果
        Color.blue.opacity(0.3)
        TopBlurView()
    }
} 
