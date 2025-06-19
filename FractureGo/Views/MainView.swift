//
//  MainView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI
import CoreData

struct MainView: View {
    @ObservedObject private var userManager = UserManager.shared
    let persistenceController = PersistenceController.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color(hex: "f5f5f0").ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // 顶部用户信息
                    VStack(spacing: 15) {
                        Text("FractureGo")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        if let user = userManager.currentUser {
                            VStack(spacing: 8) {
                                Text("欢迎回来！")
                                    .font(.title2)
                                    .foregroundColor(.black.opacity(0.8))
                                
                                Text(user.nickname)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(hex: "9ecd57"))
                                
                                Text("手机号: \(user.phoneNumber)")
                                    .font(.subheadline)
                                    .foregroundColor(.black.opacity(0.6))
                                
                                Text("用户类型: \(user.userType)")
                                    .font(.subheadline)
                                    .foregroundColor(.black.opacity(0.6))
                            }
                        }
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    // 主要功能区域
                    VStack(spacing: 20) {
                        Text("功能模块")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        
                        // 功能按钮网格
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
                            // 手势检测
                            Button(action: {
                                // TODO: 实现手势检测功能
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "hand.raised.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color(hex: "9ecd57"))
                                    Text("手势检测")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                }
                                .frame(height: 100)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(15)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                            
                            // 姿态分析
                            Button(action: {
                                // TODO: 实现姿态分析功能
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color(hex: "9ecd57"))
                                    Text("姿态分析")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                }
                                .frame(height: 100)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(15)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                            
                            // 运动训练
                            Button(action: {
                                // TODO: 实现运动训练功能
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color(hex: "9ecd57"))
                                    Text("运动训练")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                }
                                .frame(height: 100)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(15)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                            
                            // 数据报告
                            Button(action: {
                                // TODO: 实现数据报告功能
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color(hex: "9ecd57"))
                                    Text("数据报告")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                }
                                .frame(height: 100)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(15)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    
                    Spacer()
                    
                    // 退出登录按钮
                    Button(action: {
                        userManager.logout()
                    }) {
                        Text("退出登录")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    MainView()
} 