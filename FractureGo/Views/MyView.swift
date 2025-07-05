//
//  MyView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct MyView: View {
    @StateObject private var userManager = UserManager.shared
    @State private var showMLTest = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色
                Color(hex: "f5f5f0")
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // 顶部空白区域
                    Spacer()
                        .frame(height: 120)
                    
                    // 用户信息卡片
                    userInfoCard
                    
                    // 功能按钮区域
                    HStack(spacing: 15) {
                        // 记录按钮
                        functionButton(
                            icon: "record_icon",
                            title: "记录",
                            action: {
                                // 记录功能
                            }
                        )
                        
                        // 提醒按钮
                        functionButton(
                            icon: "remind_icon",
                            title: "提醒",
                            action: {
                                // 提醒功能
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // 菜单列表
                    VStack(spacing: 10) {
                        menuItem(title: "我的收藏", opacity: 0.5, action: {})
                        menuItem(title: "打卡奖励", opacity: 0.6, action: {})
                        menuItem(title: "我的课程", opacity: 0.7, action: {})
                        menuItem(title: "健康记录", opacity: 0.8, action: {})
                        menuItem(title: "帮助中心", opacity: 0.9, action: {})
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // 底部导航栏占位
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 如果用户已登录但没有用户信息，则获取用户信息
            if userManager.isLoggedIn && userManager.currentUser == nil {
                fetchUserProfile()
            }
        }
    }
    
    // 用户信息卡片
    private var userInfoCard: some View {
        HStack(spacing: 15) {
            // 用户头像
            AsyncImage(url: URL(string: userManager.currentUser?.wechatAvatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image("default_avator")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 3)
            )
            
            // 用户信息
            VStack(alignment: .leading, spacing: 4) {
                Text(userManager.currentUser?.nickname ?? "骨小康")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "2f5b28"))
                
                Text("\(calculateAge())岁")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "2f5b28"))
                
                Text("手臂受伤")
                    .font(.caption)
                    .foregroundColor(Color(hex: "2f5b28"))
                
                Text("已恢复 15 天")
                    .font(.caption)
                    .foregroundColor(Color(hex: "2f5b28"))
            }
            
            Spacer()
            
            // 右箭头
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "9ecd57").opacity(0.5))
        )
        .padding(.horizontal, 20)
    }
    
    // 功能按钮
    private func functionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.body)
                    .foregroundColor(Color(hex: "2f5b28"))
                
                Spacer()
                
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 15)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: "9ecd57").opacity(0.3))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 菜单项
    private func menuItem(title: String, opacity: Double = 1.0, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(Color(hex: "2f5b28"))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: "9ecd57").opacity(opacity))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 计算年龄
    private func calculateAge() -> Int {
        guard let birthDate = userManager.currentUser?.birthDate else {
            return 10 // 默认年龄
        }
        
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year ?? 10
    }
    
    // 获取用户信息
    private func fetchUserProfile() {
        NetworkService.shared.getUserProfile { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    // 更新用户信息
                    let dateFormatter = ISO8601DateFormatter()
                    let birthDate = dateFormatter.date(from: user.birthDate) ?? Date()
                    
                    userManager.currentUser = UserManager.UserData(
                        nickname: user.nickname,
                        phoneNumber: user.phoneNumber,
                        userType: user.userType,
                        birthDate: birthDate,
                        isWeChatUser: user.isWeChatUser,
                        wechatNickname: user.wechatNickname,
                        wechatAvatarUrl: user.wechatAvatarUrl
                    )
                case .failure(let error):
                    print("获取用户信息失败: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    MyView()
}
