//
//  TopBlurView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct TopBlurView: View {
    var body: some View {
        VStack {
            WaveShape()
                .fill(Color(hex: "9ecd57"))
                .frame(height: 160)
                .ignoresSafeArea(edges: .top)
            Spacer()
        }
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
        path.addLine(to: CGPoint(x: width, y: height * 0.45))
        
        // 更自然的波浪形底边
        // 第一个波浪 - 从右侧开始的大波浪
        path.addCurve(
            to: CGPoint(x: width * 0.75, y: height * 0.7),
            control1: CGPoint(x: width * 0.92, y: height * 0.55),
            control2: CGPoint(x: width * 0.83, y: height * 0.75)
        )
        
        // 第二个波浪 - 中等波浪
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.85),
            control1: CGPoint(x: width * 0.67, y: height * 0.65),
            control2: CGPoint(x: width * 0.58, y: height * 0.9)
        )
        
        // 第三个波浪 - 较小的波浪
        path.addCurve(
            to: CGPoint(x: width * 0.25, y: height * 0.9),
            control1: CGPoint(x: width * 0.42, y: height * 0.8),
            control2: CGPoint(x: width * 0.33, y: height * 0.95)
        )
        
        // 最后一段平滑过渡到左边缘
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.75),
            control1: CGPoint(x: width * 0.17, y: height * 0.85),
            control2: CGPoint(x: width * 0.08, y: height * 0.8)
        )
        
        // 左边缘回到起点
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        return path
    }
}

// 颜色扩展，支持十六进制颜色
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    TopBlurView()
} 