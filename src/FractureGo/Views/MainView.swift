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
        ZStack {
            // 主要内容 - 使用原生TabView但隐藏原生tabBar
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        // 隐藏的tabItem
                        EmptyView()
                    }
                    .tag(0)
                
                SignInView()
                    .tabItem {
                        EmptyView()
                    }
                    .tag(1)
                
                CardListView()
                    .tabItem {
                        EmptyView()
                    }
                    .tag(2)
                
                ShareView()
                    .tabItem {
                        EmptyView()
                    }
                    .tag(3)
                
                MyView()
                    .tabItem {
                        EmptyView()
                    }
                    .tag(4)
            }
            .onAppear {
                // 隐藏原生TabBar
                UITabBar.appearance().isHidden = true
            }
            
            // 自定义底部导航栏 - overlay在TabView上方
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
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "E3F297"))
                    
                    // 底部安全区域 - 确保完全覆盖
                    Color(hex: "E3F297")
                        .frame(maxWidth: .infinity)
                        .frame(height: 35) // 减少底部高度
                }
                .background(Color(hex: "E3F297"))
            }
            .ignoresSafeArea(.all)
            
            // 顶部波浪遮挡 - 使用TopBlurView统一实现
            VStack {
                TopBlurView()
                    .allowsHitTesting(false) // 允许点击穿透
                    .zIndex(1000) // 设置TopBlurView的层级
                Spacer()
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
        .frame(height: 50)
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
}

// 卡片列表视图
struct CardListView: View {
    @State private var showHandLevel = false
    @State private var showArmLevel = false
    @State private var showLegLevel = false
    
    var body: some View {
        VStack {
            // 顶部空白区域 - 为TopBlurView预留空间
            Spacer()
                .frame(height: 60)
            
            Spacer() // 自动填充上方空间
            
            VStack(spacing: 35) {
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
            }
            .padding(.horizontal, 24) // 左右边距
            
            Spacer() // 自动填充下方空间
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "f5f5f0"))
    }
}

// 卡片图片视图组件
struct CardImageView: View {
    let imageName: String
    let title: String
    
    var body: some View {
        VStack(spacing: 0) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: 140)
                .clipped()
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .frame(maxWidth: .infinity, maxHeight: 140)
        .padding(.horizontal, 8) // 给卡片增加一点内边距，让阴影不被裁切
    }
}

#Preview {
    MainView()
} 
