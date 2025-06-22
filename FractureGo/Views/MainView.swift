//
//  MainView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI
import CoreData

struct MainView: View {
    @State private var selectedTab = 0 // 默认选中HomeView
    
    let persistenceController = PersistenceController.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color(hex: "f5f5f0").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部波浪遮挡
                    WaveShape()
                        .fill(Color(hex: "9ecd57"))
                        .frame(height: 160)
                        .ignoresSafeArea(edges: .top)
                    
                    // 中间内容区域 - 灵活高度
                    NavigationView {
                        ZStack {
                            switch selectedTab {
                            case 0:
                                HomeView()
                            case 1:
                                SignInView()
                            case 2:
                                CardListView() // 主图标显示卡片列表
                            case 3:
                                ShareView()
                            case 4:
                                MyView()
                            default:
                                HomeView()
                            }
                        }
                        .navigationBarHidden(true)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // 底部导航栏 - 完全贴合屏幕底部
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            // Home图标
                            TabBarItem(
                                iconName: "home_icon",
                                isSelected: selectedTab == 0,
                                isMainIcon: false,
                                action: { selectedTab = 0 }
                            )
                            
                            // SignIn图标
                            TabBarItem(
                                iconName: "SignIn_icon",
                                isSelected: selectedTab == 1,
                                isMainIcon: false,
                                action: { selectedTab = 1 }
                            )
                            
                            // Main图标（中间，更大）
                            TabBarItem(
                                iconName: "main_icon",
                                isSelected: selectedTab == 2,
                                isMainIcon: true,
                                action: { selectedTab = 2 }
                            )
                            
                            // Share图标
                            TabBarItem(
                                iconName: "Share_icon",
                                isSelected: selectedTab == 3,
                                isMainIcon: false,
                                action: { selectedTab = 3 }
                            )
                            
                            // My图标
                            TabBarItem(
                                iconName: "my_icon",
                                isSelected: selectedTab == 4,
                                isMainIcon: false,
                                action: { selectedTab = 4 }
                            )
                        }
                        .frame(height: 60)
                        .background(Color(hex: "E3F297"))
                        
                        // 底部安全区域填充
                        Rectangle()
                            .fill(Color(hex: "E3F297"))
                            .frame(height: geometry.safeAreaInsets.bottom)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.keyboard) // 防止键盘影响布局
    }
}

// 这些占位符内容视图已被实际的View替代

// 底部导航栏项目组件
struct TabBarItem: View {
    let iconName: String
    let isSelected: Bool
    let isMainIcon: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: isMainIcon ? 44 : 36,  // main_icon更大，其他图标也变大
                        height: isMainIcon ? 44 : 36
                    )
                    .foregroundColor(isSelected ? Color(hex: "9ecd57") : .gray)
                
                // 选中状态下的小圆点
                if isSelected {
                    Circle()
                        .fill(Color(hex: "9ecd57"))
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
    }
}

// 卡片列表视图
struct CardListView: View {
    @State private var showHandLevel = false
    @State private var showArmLevel = false
    @State private var showLegLevel = false
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 卡片1 - 手部训练
            Button(action: {
                showHandLevel = true
            }) {
                CardImageView(imageName: "卡片1", title: "手部训练")
            }
            .buttonStyle(PlainButtonStyle())
            .fullScreenCover(isPresented: $showHandLevel) {
                HandLevelView()
            }
            
            // 卡片2 - 手臂训练
            Button(action: {
                showArmLevel = true
            }) {
                CardImageView(imageName: "卡片2", title: "手臂训练")
            }
            .buttonStyle(PlainButtonStyle())
            .fullScreenCover(isPresented: $showArmLevel) {
                ArmLevelView()
            }
            
            // 卡片3 - 腿部训练
            Button(action: {
                showLegLevel = true
            }) {
                CardImageView(imageName: "卡片3", title: "腿部训练")
            }
            .buttonStyle(PlainButtonStyle())
            .fullScreenCover(isPresented: $showLegLevel) {
                LegLevelView()
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "f5f5f0"))
    }
}

// 卡片图片视图组件
struct CardImageView: View {
    let imageName: String
    let title: String
    
    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 300, height: 140)
                .clipped()
                .cornerRadius(16)
            
            Spacer(minLength: 0)
        }
        .frame(width: 300, height: 140)
    }
}

#Preview {
    MainView()
} 
