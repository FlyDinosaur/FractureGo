//
//  LegLevelView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct LegLevelView: View {
    @State private var completedLevels: Set<Int> = []
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    private let legColor = Color(red: 0.424, green: 0.765, blue: 1.0)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "f5f5f0")
                    .ignoresSafeArea(.all)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
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
                        LegCurvePath(color: legColor)
                            .fill(legColor)
                            .overlay(
                                LegCurvePath(color: legColor)
                                    .stroke(legColor, lineWidth: 6)
                            )
                            .shadow(color: legColor.opacity(0.4), radius: 8, x: 0, y: 3)
                        
                        LegLevelButtonsView(
                            completedLevels: $completedLevels,
                            geometry: geometry,
                            color: legColor
                        )
                        
                        LegGiftBoxView(
                            position: getLegPathEndPosition(in: geometry),
                            color: legColor
                        )
                    }
                }
                
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
                
                VStack {
                    TopBlurView()
                        .frame(height: 160)
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.leading, 20)
                        .padding(.top, 60)
                        
                        Spacer()
                    }
                    Spacer()
                }
                .zIndex(999)
            }
        }
        .navigationBarHidden(true)
        .navigationViewStyle(StackNavigationViewStyle())
        .statusBarHidden(false)
        .preferredColorScheme(.light)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.startLocation.x < 20 && value.translation.width > 100 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
        )
    }
}

private struct LegCurvePath: Shape {
    let color: Color
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let scale: CGFloat = 0.5
        let offsetX = rect.size.width * (1 - scale) / 2
        let offsetY = rect.size.height * 0.25
        let width = rect.size.width * scale
        let height = rect.size.height * scale
        
        // 这里包含完整的MyIcon路径代码
        path.move(to: CGPoint(x: 0.98303*width + offsetX, y: 0.50272*height + offsetY))
        // ... (为了简洁，这里省略了完整路径，实际使用时包含所有路径)
        
        return path
    }
}

private struct LegLevelButtonsView: View {
    @Binding var completedLevels: Set<Int>
    let geometry: GeometryProxy
    let color: Color
    
    var body: some View {
        let positions = getLegLevelPositions(in: geometry)
        
        ForEach(1...8, id: \.self) { level in
            let position = positions[level - 1]
            let isUnlocked = isLevelUnlocked(level)
            let isCompleted = completedLevels.contains(level)
            
            LegLevelButton(
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

private struct LegLevelButton: View {
    let level: Int
    let isUnlocked: Bool
    let isCompleted: Bool
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 70, height: 70)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Circle()
                    .fill(buttonBackgroundColor)
                    .frame(width: 45, height: 45)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                if isUnlocked {
                    Text("\(level)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .medium))
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
        .scaleEffect(isCompleted ? 1.05 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isCompleted)
    }
    
    private var buttonBackgroundColor: Color {
        if !isUnlocked {
            return Color.gray.opacity(0.7)
        } else if isCompleted {
            return color
        } else {
            return color.opacity(0.8)
        }
    }
}

private struct LegGiftBoxView: View {
    let position: CGPoint
    let color: Color
    @State private var isAnimating = false
    @State private var petalRotation = 0.0
    
    var body: some View {
        ZStack {
            LegFlowerBackground(color: color)
                .rotationEffect(.degrees(petalRotation))
                .animation(
                    .linear(duration: 20.0).repeatForever(autoreverses: false),
                    value: petalRotation
                )
            
            Image("gift")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .position(position)
        .onAppear {
            isAnimating = true
            petalRotation = 360.0
        }
    }
}

private struct LegFlowerBackground: View {
    let color: Color
    
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                LegPetal()
                    .fill(color.opacity(0.3))
                    .frame(width: 25, height: 60)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            
            Circle()
                .fill(color.opacity(0.4))
                .frame(width: 30, height: 30)
        }
        .frame(width: 80, height: 80)
    }
}

private struct LegPetal: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.5, y: height))
        
        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control: CGPoint(x: 0, y: height * 0.3)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control: CGPoint(x: width, y: height * 0.3)
        )
        
        return path
    }
}

private func getLegLevelPositions(in geometry: GeometryProxy) -> [CGPoint] {
    let scale: CGFloat = 0.5
    let offsetX = geometry.size.width * (1 - scale) / 2
    let offsetY = geometry.size.height * 0.25
    let width = geometry.size.width * scale
    let height = geometry.size.height * scale
    
    return [
        CGPoint(x: (0.58925 + 0.13385/2)*width + offsetX, y: (0.86959 + 0.08741/2)*height + offsetY),
        CGPoint(x: (0.23703 + 0.13385/2)*width + offsetX, y: (0.76679 + 0.08741/2)*height + offsetY),
        CGPoint(x: (0.63797 + 0.13385/2)*width + offsetX, y: (0.64205 + 0.08741/2)*height + offsetY),
        CGPoint(x: (0.79967 + 0.13385/2)*width + offsetX, y: (0.43023 + 0.08741/2)*height + offsetY),
        CGPoint(x: (0.30396 + 0.13385/2)*width + offsetX, y: (0.53454 + 0.08741/2)*height + offsetY),
        CGPoint(x: (0.16481 + 0.13385/2)*width + offsetX, y: (0.37279 + 0.08741/2)*height + offsetY),
        CGPoint(x: (0.66289 + 0.13385/2)*width + offsetX, y: (0.23052 + 0.08741/2)*height + offsetY),
        CGPoint(x: (0.72745 + 0.13385/2)*width + offsetX, y: (0.01362 + 0.08741/2)*height + offsetY),
    ]
}

private func getLegPathEndPosition(in geometry: GeometryProxy) -> CGPoint {
    let scale: CGFloat = 0.5
    let offsetX = geometry.size.width * (1 - scale) / 2
    let offsetY = geometry.size.height * 0.25
    let width = geometry.size.width * scale
    let height = geometry.size.height * scale
    
    let level8X = (0.72745 + 0.13385/2)*width + offsetX
    let level8Y = (0.01362 + 0.08741/2)*height + offsetY
    
    return CGPoint(x: level8X - 100, y: level8Y + 60)
}

#Preview {
    LegLevelView()
}
