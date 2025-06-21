//
//  HomeView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct HomeView: View {
    @State private var currentIndex = 0
    @State private var showHandLevel = false
    @State private var showArmLevel = false
    @State private var showLegLevel = false
    
    // 训练数据
    let trainings = [
        Training(
            title: "手部训练",
            backgroundImage: "Hand",
            characterImage: "Hand_cartoon",
            arrowColor: "f19ca2"
        ),
        Training(
            title: "手臂训练", 
            backgroundImage: "Arm",
            characterImage: "Arm_cartoon",
            arrowColor: "9ecd57"
        ),
        Training(
            title: "腿部训练",
            backgroundImage: "Leg",
            characterImage: "Leg_cartoon",
            arrowColor: "9f98fb"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题区域
            VStack(spacing: 10) {
                Text(trainings[currentIndex].title)
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: trainings[currentIndex].arrowColor))
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)
            
            // 卡片轮播区域
            TabView(selection: $currentIndex) {
                ForEach(trainings.indices, id: \.self) { index in
                    TrainingCardView(
                        training: trainings[index],
                        onTap: {
                            switch index {
                            case 0:
                                showHandLevel = true
                            case 1:
                                showArmLevel = true
                            case 2:
                                showLegLevel = true
                            default:
                                break
                            }
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 350)
            .animation(.easeInOut(duration: 0.5), value: currentIndex)
            .onChange(of: currentIndex) { oldValue, newValue in
                // 当滑动到边界时自动循环
                if newValue < 0 {
                    currentIndex = trainings.count - 1
                } else if newValue >= trainings.count {
                    currentIndex = 0
                }
            }
            
            Spacer(minLength: 20)
            
            // 滑动指示器
            HStack(spacing: 30) {
                // 左箭头
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentIndex = currentIndex > 0 ? currentIndex - 1 : trainings.count - 1
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(Color(hex: trainings[currentIndex].arrowColor))
                        Text("...")
                            .font(.title3)
                            .foregroundColor(Color(hex: trainings[currentIndex].arrowColor))
                    }
                }
                
                Spacer()
                
                // 右箭头
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentIndex = currentIndex < trainings.count - 1 ? currentIndex + 1 : 0
                    }
                }) {
                    HStack(spacing: 5) {
                        Text("...")
                            .font(.title3)
                            .foregroundColor(Color(hex: trainings[currentIndex].arrowColor))
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundColor(Color(hex: trainings[currentIndex].arrowColor))
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
            
            // 滑动提示文字
            Text("左右滑动选择")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.6))
                .padding(.bottom, 30)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "f5f5f0"))
        .fullScreenCover(isPresented: $showHandLevel) {
            HandLevelView()
        }
        .fullScreenCover(isPresented: $showArmLevel) {
            ArmLevelView()
        }
        .fullScreenCover(isPresented: $showLegLevel) {
            LegLevelView()
        }
    }
}

// 训练数据模型
struct Training {
    let title: String
    let backgroundImage: String
    let characterImage: String
    let arrowColor: String
}

// 训练卡片视图
struct TrainingCardView: View {
    let training: Training
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 背景圆形 - 扩大尺寸确保完全显示
                Image(training.backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 320, height: 320)
                
                // 卡通动物角色 - 确保在背景之上
                Image(training.characterImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 240, height: 240)
                    .offset(y: -10)
                    .zIndex(1)
            }
            .frame(width: 320, height: 320)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView()
} 