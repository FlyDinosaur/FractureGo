//
//  WeChatBindingView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct WeChatBindingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var nickname = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var birthDate = Date()
    @State private var selectedUserType: UserType = .child
    @State private var showDatePicker = false
    @State private var showMainView = false
    
    enum UserType: String, CaseIterable {
        case child = "儿童"
        case parent = "家长"
        case doctor = "医生"
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color(hex: "f5f5f0").ignoresSafeArea()
            
            // 顶部波浪遮挡
            TopBlurView()
            
            ScrollView {
                VStack(spacing: 25) {
                    // 返回按钮
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.title2)
                                .padding()
                        }
                        Spacer()
                    }
                    .padding(.top, 50)
                    
                    // 绑定标题
                    VStack(spacing: 10) {
                        Text("绑定账户信息")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(Color(hex: "9ecd57"))
                        
                        Text("完善您的个人信息")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 20)
                    
                    // 输入框组
                    VStack(spacing: 20) {
                        // 昵称输入框
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField("昵称（用户名）", text: $nickname)
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(25)
                        }
                        
                        // 手机号输入框
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField("手机号码", text: $phoneNumber)
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                    .keyboardType(.phonePad)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(25)
                        }
                        
                        // 密码输入框
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                SecureField("设置密码", text: $password)
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(25)
                        }
                        
                        // 确认密码输入框
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                SecureField("确认密码", text: $confirmPassword)
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(password == confirmPassword ? Color.gray.opacity(0.3) : Color.red, lineWidth: 1)
                            )
                            .cornerRadius(25)
                        }
                        
                        // 出生日期选择器
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                showDatePicker = true
                            }) {
                                HStack {
                                    Text(birthDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "calendar")
                                        .foregroundColor(Color(hex: "9ecd57"))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 15)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(25)
                            }
                        }
                        
                        // 用户类型选择器
                        VStack(alignment: .leading, spacing: 8) {
                            Text("账户类别")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .padding(.leading, 20)
                            
                            Menu {
                                ForEach(UserType.allCases, id: \.self) { type in
                                    Button(type.rawValue) {
                                        selectedUserType = type
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedUserType.rawValue)
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(Color(hex: "9ecd57"))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 15)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(25)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // 绑定按钮
                    Button(action: {
                        handleBinding()
                    }) {
                        Text("完成绑定")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isFormValid() ? Color(hex: "9ecd57") : Color.gray)
                            .cornerRadius(25)
                    }
                    .disabled(!isFormValid())
                    .padding(.horizontal, 30)
                    .padding(.bottom, 60)
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePicker("选择出生日期", selection: $birthDate, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showMainView) {
            MainView()
        }
    }
    
    private func isFormValid() -> Bool {
        return !nickname.isEmpty &&
               !phoneNumber.isEmpty &&
               !password.isEmpty &&
               password == confirmPassword &&
               password.count >= 6
    }
    
    private func handleBinding() {
        // 这里实现微信绑定逻辑
        // 保存用户信息到数据库（密码需要MD5加密）
        let hashedPassword = password.md5
        
        // 模拟保存用户数据
        let userData: [String: Any] = [
            "nickname": nickname,
            "phoneNumber": phoneNumber,
            "password": hashedPassword,
            "birthDate": birthDate,
            "userType": selectedUserType.rawValue,
            "isWeChatUser": true
        ]
        
        // 保存到UserDefaults（实际应用中应该保存到数据库）
        UserDefaults.standard.set(userData, forKey: "userData_\(phoneNumber)")
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        
        // 绑定成功，跳转到主界面
        showMainView = true
    }
}

#Preview {
    WeChatBindingView()
} 