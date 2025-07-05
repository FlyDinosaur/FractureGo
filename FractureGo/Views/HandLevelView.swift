//
//  HandLevelView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct HandLevelView: View {
    @State private var completedLevels: Set<Int> = [] // 从服务器获取的完成关卡
    @State private var currentLevel: Int = 1 // 当前解锁的关卡
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode // 添加系统presentation模式
    private let handColor = Color(red: 1.0, green: 0.706, blue: 0.694) // #ffb4b1
    
    var body: some View {
        ZStack {
            NavigationView {
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
                            // 3. S形曲线路径 - 填充闭合部分 + 描边
                            HandCurvePath(color: handColor)
                                .fill(handColor)
                                .overlay(
                                    HandCurvePath(color: handColor)
                                        .stroke(handColor, lineWidth: 6)
                                )
                                .shadow(color: handColor.opacity(0.4), radius: 8, x: 0, y: 3)
                            
                            // 4. 关卡按钮（第1关在底部，重新排序）
                            HandLevelButtonsView(
                                completedLevels: $completedLevels,
                                currentLevel: currentLevel,
                                geometry: geometry,
                                color: handColor,
                                onRefreshProgress: loadTrainingProgress
                            )
                            
                            // 5. 礼品盒 - 位于第8关左下方
                            HandGiftBoxView(
                                position: getHandPathEndPosition(in: geometry),
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
                }
            }
            .navigationBarHidden(true)
            .navigationViewStyle(StackNavigationViewStyle()) // 恢复系统级返回支持
            .statusBarHidden(false)
            .preferredColorScheme(.light)
            .onAppear {
                // 启用系统级右滑返回手势 - 使用现代iOS方法
                DispatchQueue.main.async {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let navigationController = window.rootViewController as? UINavigationController {
                        navigationController.interactivePopGestureRecognizer?.isEnabled = true
                    }
                }
                // 获取训练进度
                loadTrainingProgress()
            }
            
            // 7. TopBlurView - 顶部遮挡 - 最外层确保显示
            TopBlurView()
                .allowsHitTesting(false) // 允许点击穿透
                .zIndex(100) // 确保在所有内容之上
            
            // 8. 返回按钮 - 最外层确保在TopBlurView之上
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
                    .padding(.top, 60) // 确保在安全区域内
                    
                    Spacer()
                }
                Spacer()
            }
            .zIndex(300) // 最高层级，确保可见
        }
    }
    
    // MARK: - 训练进度相关方法
    private func loadTrainingProgress() {
        let networkService = NetworkService.shared
        
        networkService.getTrainingProgress(trainingType: "hand") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let progressList):
                    print("✅ 训练进度获取成功，数据条数: \(progressList.count)")
                    if let handProgress = progressList.first {
                        // 更新当前关卡
                        self.currentLevel = handProgress.currentLevel
                        
                        // 更新完成的关卡（当前关卡之前的所有关卡都算完成）
                        self.completedLevels = Set(1..<handProgress.currentLevel)
                        
                        print("✅ 手部训练进度加载成功：当前关卡 \(handProgress.currentLevel)，完成关卡 \(self.completedLevels)")
                    } else {
                        // 没有进度记录，使用默认值
                        self.currentLevel = 1
                        self.completedLevels = []
                        print("⚠️ 没有找到手部训练进度记录，使用默认值")
                    }
                case .failure(let error):
                    print("❌ 获取训练进度失败: \(error)")
                    // 失败时使用默认值
                    self.currentLevel = 1
                    self.completedLevels = []
                }
            }
        }
    }
}

// 手部关卡按钮视图（第1关在底部，重新排序）
private struct HandLevelButtonsView: View {
    @Binding var completedLevels: Set<Int>
    let currentLevel: Int
    let geometry: GeometryProxy
    let color: Color
    let onRefreshProgress: () -> Void
    @State private var selectedLevel: Int? = nil
    @State private var showHandRecoverView = false
    
    var body: some View {
        let positions = getHandLevelPositions(in: geometry)
        
        ZStack {
            ForEach(1...8, id: \.self) { level in
                let position = positions[level - 1]
                let isUnlocked = isLevelUnlocked(level)
                let isCompleted = completedLevels.contains(level)
                
                HandLevelButton(
                    level: level,
                    isUnlocked: isUnlocked,
                    isCompleted: isCompleted,
                    color: color
                ) {
                    if isUnlocked {
                        print("Button tapped for level \(level)")
                        selectedLevel = level
                        DispatchQueue.main.async {
                            showHandRecoverView = true
                            print("Setting showHandRecoverView to true for level \(level)")
                        }
                    }
                }
                .position(position)
            }
        }
        .fullScreenCover(isPresented: $showHandRecoverView) {
            HandRecoverView(level: selectedLevel ?? 1)
                .onAppear {
                    print("Presenting HandRecoverView for level \(selectedLevel ?? 1)")
                }
                .onDisappear {
                    // 游戏结束后刷新训练进度
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onRefreshProgress()
                    }
                }
        }
    }
    
    private func isLevelUnlocked(_ level: Int) -> Bool {
        return level <= currentLevel
    }
}

// MARK: - 基于MyIcon的完整路径，等比例缩放到页面内
private struct HandCurvePath: Shape {
    let color: Color
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 等比例缩放参数：缩小到50%，居中显示，向下移动
        let scale: CGFloat = 0.5
        let offsetX = rect.size.width * (1 - scale) / 2
        let offsetY = rect.size.height * 0.25 // 向下移动25%
        let width = rect.size.width * scale
        let height = rect.size.height * scale
        
        // 完全保留您MyIcon代码的所有路径细节，只进行等比例缩放和偏移
        path.move(to: CGPoint(x: 0.98303*width + offsetX, y: 0.50272*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.95072*width + offsetX, y: 0.47007*height + offsetY), control1: CGPoint(x: 0.97474*width + offsetX, y: 0.49061*height + offsetY), control2: CGPoint(x: 0.96375*width + offsetX, y: 0.47968*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.86541*width + offsetX, y: 0.4187*height + offsetY), control1: CGPoint(x: 0.94717*width + offsetX, y: 0.44131*height + offsetY), control2: CGPoint(x: 0.91035*width + offsetX, y: 0.4187*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.81963*width + offsetX, y: 0.42743*height + offsetY), control1: CGPoint(x: 0.84856*width + offsetX, y: 0.4187*height + offsetY), control2: CGPoint(x: 0.83288*width + offsetX, y: 0.42194*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.80407*width + offsetX, y: 0.42699*height + offsetY), control1: CGPoint(x: 0.8145*width + offsetX, y: 0.42717*height + offsetY), control2: CGPoint(x: 0.80931*width + offsetX, y: 0.42699*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.72468*width + offsetX, y: 0.43803*height + offsetY), control1: CGPoint(x: 0.77656*width + offsetX, y: 0.42699*height + offsetY), control2: CGPoint(x: 0.74989*width + offsetX, y: 0.43071*height + offsetY))
        path.addLine(to: CGPoint(x: 0.41171*width + offsetX, y: 0.52912*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.37071*width + offsetX, y: 0.52231*height + offsetY), control1: CGPoint(x: 0.39953*width + offsetX, y: 0.52478*height + offsetY), control2: CGPoint(x: 0.38554*width + offsetX, y: 0.52231*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.28749*width + offsetX, y: 0.56528*height + offsetY), control1: CGPoint(x: 0.33023*width + offsetX, y: 0.52231*height + offsetY), control2: CGPoint(x: 0.29646*width + offsetX, y: 0.54065*height + offsetY))
        path.addLine(to: CGPoint(x: 0.28507*width + offsetX, y: 0.56598*height + offsetY))
        path.addLine(to: CGPoint(x: 0.28546*width + offsetX, y: 0.56661*height + offsetY))
        path.addLine(to: CGPoint(x: 0.23393*width + offsetX, y: 0.58163*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.19587*width + offsetX, y: 0.58693*height + offsetY), control1: CGPoint(x: 0.22158*width + offsetX, y: 0.58524*height + offsetY), control2: CGPoint(x: 0.20862*width + offsetX, y: 0.58693*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.10961*width + offsetX, y: 0.55052*height + offsetY), control1: CGPoint(x: 0.15979*width + offsetX, y: 0.58693*height + offsetY), control2: CGPoint(x: 0.12517*width + offsetX, y: 0.57331*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.15725*width + offsetX, y: 0.46933*height + offsetY), control1: CGPoint(x: 0.08852*width + offsetX, y: 0.51962*height + offsetY), control2: CGPoint(x: 0.11*width + offsetX, y: 0.4831*height + offsetY))
        path.addLine(to: CGPoint(x: 0.18257*width + offsetX, y: 0.46197*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.23241*width + offsetX, y: 0.4725*height + offsetY), control1: CGPoint(x: 0.19661*width + offsetX, y: 0.46856*height + offsetY), control2: CGPoint(x: 0.2138*width + offsetX, y: 0.4725*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.31755*width + offsetX, y: 0.42272*height + offsetY), control1: CGPoint(x: 0.27656*width + offsetX, y: 0.4725*height + offsetY), control2: CGPoint(x: 0.31281*width + offsetX, y: 0.4507*height + offsetY))
        path.addLine(to: CGPoint(x: 0.4298*width + offsetX, y: 0.39006*height + offsetY))
        path.addLine(to: CGPoint(x: 0.4298*width + offsetX, y: 0.39013*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.6789*width + offsetX, y: 0.31767*height + offsetY), control1: CGPoint(x: 0.6789*width + offsetX, y: 0.31767*height + offsetY), control2: CGPoint(x: 0.6789*width + offsetX, y: 0.31767*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.72959*width + offsetX, y: 0.32861*height + offsetY), control1: CGPoint(x: 0.69311*width + offsetX, y: 0.32452*height + offsetY), control2: CGPoint(x: 0.71059*width + offsetX, y: 0.32861*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.81484*width + offsetX, y: 0.27813*height + offsetY), control1: CGPoint(x: 0.77408*width + offsetX, y: 0.32861*height + offsetY), control2: CGPoint(x: 0.81061*width + offsetX, y: 0.30644*height + offsetY))
        path.addLine(to: CGPoint(x: 0.88041*width + offsetX, y: 0.25906*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.97948*width + offsetX, y: 0.09035*height + offsetY), control1: CGPoint(x: 0.97897*width + offsetX, y: 0.23038*height + offsetY), control2: CGPoint(x: 1.0234*width + offsetX, y: 0.15471*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.86401*width + offsetX, y: 0.02161*height + offsetY), control1: CGPoint(x: 0.95704*width + offsetX, y: 0.05744*height + offsetY), control2: CGPoint(x: 0.91458*width + offsetX, y: 0.03292*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.79657*width + offsetX, y: 0.00007*height + offsetY), control1: CGPoint(x: 0.84833*width + offsetX, y: 0.00854*height + offsetY), control2: CGPoint(x: 0.82397*width + offsetX, y: 0.00007*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.72598*width + offsetX, y: 0.02437*height + offsetY), control1: CGPoint(x: 0.76725*width + offsetX, y: 0.00007*height + offsetY), control2: CGPoint(x: 0.74143*width + offsetX, y: 0.00968*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.72119*width + offsetX, y: 0.02566*height + offsetY), control1: CGPoint(x: 0.7244*width + offsetX, y: 0.02482*height + offsetY), control2: CGPoint(x: 0.72277*width + offsetX, y: 0.02522*height + offsetY))
        path.addLine(to: CGPoint(x: 0.52188*width + offsetX, y: 0.08365*height + offsetY))
        path.addLine(to: CGPoint(x: 0.56033*width + offsetX, y: 0.14503*height + offsetY))
        path.addLine(to: CGPoint(x: 0.73438*width + offsetX, y: 0.09437*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.79657*width + offsetX, y: 0.11193*height + offsetY), control1: CGPoint(x: 0.75*width + offsetX, y: 0.10515*height + offsetY), control2: CGPoint(x: 0.77205*width + offsetX, y: 0.11193*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.8591*width + offsetX, y: 0.09415*height + offsetY), control1: CGPoint(x: 0.8211*width + offsetX, y: 0.11193*height + offsetY), control2: CGPoint(x: 0.84343*width + offsetX, y: 0.10508*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.88684*width + offsetX, y: 0.1173*height + offsetY), control1: CGPoint(x: 0.87071*width + offsetX, y: 0.10011*height + offsetY), control2: CGPoint(x: 0.88041*width + offsetX, y: 0.10792*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.8392*width + offsetX, y: 0.19849*height + offsetY), control1: CGPoint(x: 0.90793*width + offsetX, y: 0.1482*height + offsetY), control2: CGPoint(x: 0.88645*width + offsetX, y: 0.18472*height + offsetY))
        path.addLine(to: CGPoint(x: 0.76212*width + offsetX, y: 0.22091*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.7297*width + offsetX, y: 0.21672*height + offsetY), control1: CGPoint(x: 0.75209*width + offsetX, y: 0.21823*height + offsetY), control2: CGPoint(x: 0.74115*width + offsetX, y: 0.21672*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.64913*width + offsetX, y: 0.25379*height + offsetY), control1: CGPoint(x: 0.69255*width + offsetX, y: 0.21672*height + offsetY), control2: CGPoint(x: 0.66103*width + offsetX, y: 0.23218*height + offsetY))
        path.addLine(to: CGPoint(x: 0.5667*width + offsetX, y: 0.2778*height + offsetY))
        path.addLine(to: CGPoint(x: 0.5667*width + offsetX, y: 0.27772*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.26624*width + offsetX, y: 0.36517*height + offsetY), control1: CGPoint(x: 0.26624*width + offsetX, y: 0.36517*height + offsetY), control2: CGPoint(x: 0.26624*width + offsetX, y: 0.36517*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.23258*width + offsetX, y: 0.36068*height + offsetY), control1: CGPoint(x: 0.25592*width + offsetX, y: 0.3623*height + offsetY), control2: CGPoint(x: 0.24453*width + offsetX, y: 0.36068*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.15161*width + offsetX, y: 0.39853*height + offsetY), control1: CGPoint(x: 0.19497*width + offsetX, y: 0.36068*height + offsetY), control2: CGPoint(x: 0.16311*width + offsetX, y: 0.37651*height + offsetY))
        path.addLine(to: CGPoint(x: 0.11615*width + offsetX, y: 0.40884*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.01708*width + offsetX, y: 0.57754*height + offsetY), control1: CGPoint(x: 0.01759*width + offsetX, y: 0.43752*height + offsetY), control2: CGPoint(x: -0.02684*width + offsetX, y: 0.51318*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.19604*width + offsetX, y: 0.65328*height + offsetY), control1: CGPoint(x: 0.04849*width + offsetX, y: 0.62353*height + offsetY), control2: CGPoint(x: 0.11874*width + offsetX, y: 0.65328*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.27543*width + offsetX, y: 0.64223*height + offsetY), control1: CGPoint(x: 0.22356*width + offsetX, y: 0.65328*height + offsetY), control2: CGPoint(x: 0.25023*width + offsetX, y: 0.64956*height + offsetY))
        path.addLine(to: CGPoint(x: 0.32837*width + offsetX, y: 0.6268*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.37088*width + offsetX, y: 0.63424*height + offsetY), control1: CGPoint(x: 0.34089*width + offsetX, y: 0.63152*height + offsetY), control2: CGPoint(x: 0.35544*width + offsetX, y: 0.63424*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.45461*width + offsetX, y: 0.59006*height + offsetY), control1: CGPoint(x: 0.41199*width + offsetX, y: 0.63424*height + offsetY), control2: CGPoint(x: 0.44632*width + offsetX, y: 0.61532*height + offsetY))
        path.addLine(to: CGPoint(x: 0.71499*width + offsetX, y: 0.51429*height + offsetY))
        path.addLine(to: CGPoint(x: 0.71459*width + offsetX, y: 0.51362*height + offsetY))
        path.addLine(to: CGPoint(x: 0.76613*width + offsetX, y: 0.4986*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.78552*width + offsetX, y: 0.49455*height + offsetY), control1: CGPoint(x: 0.7725*width + offsetX, y: 0.49676*height + offsetY), control2: CGPoint(x: 0.77898*width + offsetX, y: 0.49543*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.86553*width + offsetX, y: 0.53063*height + offsetY), control1: CGPoint(x: 0.79781*width + offsetX, y: 0.51561*height + offsetY), control2: CGPoint(x: 0.82894*width + offsetX, y: 0.53063*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.88943*width + offsetX, y: 0.52839*height + offsetY), control1: CGPoint(x: 0.87382*width + offsetX, y: 0.53063*height + offsetY), control2: CGPoint(x: 0.88182*width + offsetX, y: 0.52982*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.89045*width + offsetX, y: 0.52975*height + offsetY), control1: CGPoint(x: 0.88977*width + offsetX, y: 0.52883*height + offsetY), control2: CGPoint(x: 0.89017*width + offsetX, y: 0.52927*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.84281*width + offsetX, y: 0.61094*height + offsetY), control1: CGPoint(x: 0.91154*width + offsetX, y: 0.56064*height + offsetY), control2: CGPoint(x: 0.89005*width + offsetX, y: 0.59716*height + offsetY))
        path.addLine(to: CGPoint(x: 0.79319*width + offsetX, y: 0.62537*height + offsetY))
        path.addLine(to: CGPoint(x: 0.79263*width + offsetX, y: 0.62448*height + offsetY))
        path.addLine(to: CGPoint(x: 0.74808*width + offsetX, y: 0.63744*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.70456*width + offsetX, y: 0.6296*height + offsetY), control1: CGPoint(x: 0.73534*width + offsetX, y: 0.63251*height + offsetY), control2: CGPoint(x: 0.72046*width + offsetX, y: 0.6296*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.6206*width + offsetX, y: 0.67452*height + offsetY), control1: CGPoint(x: 0.663*width + offsetX, y: 0.6296*height + offsetY), control2: CGPoint(x: 0.62838*width + offsetX, y: 0.64893*height + offsetY))
        path.addLine(to: CGPoint(x: 0.34213*width + offsetX, y: 0.75556*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.33328*width + offsetX, y: 0.75832*height + offsetY), control1: CGPoint(x: 0.33914*width + offsetX, y: 0.75644*height + offsetY), control2: CGPoint(x: 0.33615*width + offsetX, y: 0.75736*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.30334*width + offsetX, y: 0.75475*height + offsetY), control1: CGPoint(x: 0.32397*width + offsetX, y: 0.75604*height + offsetY), control2: CGPoint(x: 0.31388*width + offsetX, y: 0.75475*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.21769*width + offsetX, y: 0.81068*height + offsetY), control1: CGPoint(x: 0.25603*width + offsetX, y: 0.75475*height + offsetY), control2: CGPoint(x: 0.21769*width + offsetX, y: 0.77979*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.23201*width + offsetX, y: 0.84161*height + offsetY), control1: CGPoint(x: 0.21769*width + offsetX, y: 0.82213*height + offsetY), control2: CGPoint(x: 0.22299*width + offsetX, y: 0.83273*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.24312*width + offsetX, y: 0.92426*height + offsetY), control1: CGPoint(x: 0.22187*width + offsetX, y: 0.8683*height + offsetY), control2: CGPoint(x: 0.22468*width + offsetX, y: 0.89728*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.42208*width + offsetX, y: height + offsetY), control1: CGPoint(x: 0.27453*width + offsetX, y: 0.97025*height + offsetY), control2: CGPoint(x: 0.34478*width + offsetX, y: height + offsetY))
        path.addCurve(to: CGPoint(x: 0.50147*width + offsetX, y: 0.98895*height + offsetY), control1: CGPoint(x: 0.44959*width + offsetX, y: height + offsetY), control2: CGPoint(x: 0.47626*width + offsetX, y: 0.99628*height + offsetY))
        path.addLine(to: CGPoint(x: 0.60639*width + offsetX, y: 0.95839*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.65652*width + offsetX, y: 0.96904*height + offsetY), control1: CGPoint(x: 0.62049*width + offsetX, y: 0.96506*height + offsetY), control2: CGPoint(x: 0.6378*width + offsetX, y: 0.96904*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.74216*width + offsetX, y: 0.91311*height + offsetY), control1: CGPoint(x: 0.70382*width + offsetX, y: 0.96904*height + offsetY), control2: CGPoint(x: 0.74216*width + offsetX, y: 0.944*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.65652*width + offsetX, y: 0.85718*height + offsetY), control1: CGPoint(x: 0.74216*width + offsetX, y: 0.88222*height + offsetY), control2: CGPoint(x: 0.70382*width + offsetX, y: 0.85718*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.57567*width + offsetX, y: 0.89477*height + offsetY), control1: CGPoint(x: 0.61908*width + offsetX, y: 0.85718*height + offsetY), control2: CGPoint(x: 0.58734*width + offsetX, y: 0.8729*height + offsetY))
        path.addLine(to: CGPoint(x: 0.46008*width + offsetX, y: 0.92839*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.42202*width + offsetX, y: 0.93369*height + offsetY), control1: CGPoint(x: 0.44773*width + offsetX, y: 0.932*height + offsetY), control2: CGPoint(x: 0.43477*width + offsetX, y: 0.93369*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.33576*width + offsetX, y: 0.89728*height + offsetY), control1: CGPoint(x: 0.38594*width + offsetX, y: 0.93369*height + offsetY), control2: CGPoint(x: 0.35132*width + offsetX, y: 0.92007*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.3286*width + offsetX, y: 0.8641*height + offsetY), control1: CGPoint(x: 0.32843*width + offsetX, y: 0.88649*height + offsetY), control2: CGPoint(x: 0.32634*width + offsetX, y: 0.87507*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.38864*width + offsetX, y: 0.81454*height + offsetY), control1: CGPoint(x: 0.36169*width + offsetX, y: 0.85744*height + offsetY), control2: CGPoint(x: 0.38616*width + offsetX, y: 0.83796*height + offsetY))
        path.addLine(to: CGPoint(x: 0.43302*width + offsetX, y: 0.80162*height + offsetY))
        path.addLine(to: CGPoint(x: 0.43358*width + offsetX, y: 0.8025*height + offsetY))
        path.addLine(to: CGPoint(x: 0.66514*width + offsetX, y: 0.73513*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.70456*width + offsetX, y: 0.74142*height + offsetY), control1: CGPoint(x: 0.67693*width + offsetX, y: 0.73914*height + offsetY), control2: CGPoint(x: 0.69035*width + offsetX, y: 0.74142*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.78738*width + offsetX, y: 0.69952*height + offsetY), control1: CGPoint(x: 0.74442*width + offsetX, y: 0.74142*height + offsetY), control2: CGPoint(x: 0.7778*width + offsetX, y: 0.7236*height + offsetY))
        path.addLine(to: CGPoint(x: 0.88408*width + offsetX, y: 0.67135*height + offsetY))
        path.addCurve(to: CGPoint(x: 0.98314*width + offsetX, y: 0.50265*height + offsetY), control1: CGPoint(x: 0.98263*width + offsetX, y: 0.64267*height + offsetY), control2: CGPoint(x: 1.02706*width + offsetX, y: 0.56701*height + offsetY))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - 关卡按钮
private struct HandLevelButton: View {
    let level: Int
    let isUnlocked: Bool
    let isCompleted: Bool
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            // 大圆形背景 (半透明背景，不是白色)
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 70, height: 70)
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.4), lineWidth: 2)
                )
            
            // 按钮主体
            Circle()
                .fill(buttonBackgroundColor)
                .frame(width: 45, height: 45)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                .scaleEffect(isPressed ? 0.95 : 1.0)
            
            // 按钮内容
            if isUnlocked {
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(level)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isCompleted ? 1.05 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isCompleted)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }
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

// MARK: - 礼品盒视图（带花型背景）
private struct HandGiftBoxView: View {
    let position: CGPoint
    let color: Color
    @State private var petalRotation = 0.0
    
    var body: some View {
        ZStack {
            // 花型背景
            HandFlowerBackground(color: color)
                .rotationEffect(.degrees(petalRotation))
                .animation(
                    .linear(duration: 20.0).repeatForever(autoreverses: false),
                    value: petalRotation
                )
            
            // 礼品盒 - 放大一倍，移除跳动动画
            Image("gift")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
        }
        .position(position)
        .onAppear {
            petalRotation = 360.0
        }
    }
}

// MARK: - 花型背景
private struct HandFlowerBackground: View {
    let color: Color
    
    var body: some View {
        ZStack {
            // 8个花瓣
            ForEach(0..<8, id: \.self) { index in
                HandPetal()
                    .fill(color.opacity(0.3))
                    .frame(width: 25, height: 60)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            
            // 中心圆
            Circle()
                .fill(color.opacity(0.4))
                .frame(width: 30, height: 30)
        }
        .frame(width: 80, height: 80)
    }
}

// MARK: - 花瓣形状
private struct HandPetal: Shape {
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

// MARK: - 获取关卡位置（重新排序，第1关在最底部）
private func getHandLevelPositions(in geometry: GeometryProxy) -> [CGPoint] {
    // 应用相同的缩放和偏移参数
    let scale: CGFloat = 0.5
    let offsetX = geometry.size.width * (1 - scale) / 2
    let offsetY = geometry.size.height * 0.25 // 向下移动25%
    let width = geometry.size.width * scale
    let height = geometry.size.height * scale
    
    // 重新排序关卡：第1关在最底部，修正第4、5关顺序
    // 使用您MyIcon代码中椭圆的中心位置，重新分配关卡顺序
    return [
        CGPoint(x: (0.58925 + 0.13385/2)*width + offsetX, y: (0.86959 + 0.08741/2)*height + offsetY),  // 关卡1: 最底部开始
        CGPoint(x: (0.23703 + 0.13385/2)*width + offsetX, y: (0.76679 + 0.08741/2)*height + offsetY),  // 关卡2: 左下椭圆
        CGPoint(x: (0.63797 + 0.13385/2)*width + offsetX, y: (0.64205 + 0.08741/2)*height + offsetY),  // 关卡3: 右下椭圆  
        CGPoint(x: (0.79967 + 0.13385/2)*width + offsetX, y: (0.43023 + 0.08741/2)*height + offsetY),  // 关卡4: 最右侧椭圆（修正顺序）
        CGPoint(x: (0.30396 + 0.13385/2)*width + offsetX, y: (0.53454 + 0.08741/2)*height + offsetY),  // 关卡5: 中间椭圆（修正顺序）
        CGPoint(x: (0.16481 + 0.13385/2)*width + offsetX, y: (0.37279 + 0.08741/2)*height + offsetY),  // 关卡6: 左侧椭圆
        CGPoint(x: (0.66289 + 0.13385/2)*width + offsetX, y: (0.23052 + 0.08741/2)*height + offsetY),  // 关卡7: 右侧椭圆
        CGPoint(x: (0.72745 + 0.13385/2)*width + offsetX, y: (0.01362 + 0.08741/2)*height + offsetY),  // 关卡8: 右上角椭圆（最后一关）
    ]
}

// MARK: - 礼品盒位置（位于第8关左下方）
private func getHandPathEndPosition(in geometry: GeometryProxy) -> CGPoint {
    // 应用相同的缩放和偏移参数
    let scale: CGFloat = 0.5
    let offsetX = geometry.size.width * (1 - scale) / 2
    let offsetY = geometry.size.height * 0.25 // 向下移动25%
    let width = geometry.size.width * scale
    let height = geometry.size.height * scale
    
    // 第8关位置：(0.72745 + 0.13385/2, 0.01362 + 0.08741/2)
    // 礼品盒位置：第8关的左下方，距离更远
    let level8X = (0.72745 + 0.13385/2)*width + offsetX
    let level8Y = (0.01362 + 0.08741/2)*height + offsetY
    
    return CGPoint(x: level8X - 100, y: level8Y + 60) // 更远的左下偏移
}

#Preview {
    HandLevelView()
}