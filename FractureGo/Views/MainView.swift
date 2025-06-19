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
                    
                    // 中间内容区域 - 减去顶部和底部导航栏的高度
                    ZStack {
                        switch selectedTab {
                        case 0:
                            HomeContentView()
                        case 1:
                            SignInContentView()
                        case 2:
                            MainContentView()
                        case 3:
                            ShareContentView()
                        case 4:
                            MyContentView()
                        default:
                            HomeContentView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: geometry.size.height - 160 - 80 - geometry.safeAreaInsets.bottom)
                    
                    Spacer(minLength: 0)
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

// Home内容视图（不包含TopBlurView）
struct HomeContentView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Text("HomeView")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// SignIn内容视图
struct SignInContentView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Text("SignInView")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 主内容视图
struct MainContentView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Text("MainView")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Share内容视图
struct ShareContentView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Text("ShareView")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// My内容视图
struct MyContentView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Text("MyView")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

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

#Preview {
    MainView()
} 