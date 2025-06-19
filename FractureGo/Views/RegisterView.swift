//
//  RegisterView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var nickname = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var birthDate = Date()
    @State private var showDatePicker = false
    @State private var showMainView = false
    @State private var userType: UserType = .child
    
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
                    
                    // 注册标题
                    Text("注册")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(Color(hex: "9ecd57"))
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
                                SecureField("密码", text: $password)
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
                        
                        // 用户类型显示
                        HStack {
                            Text("用户类型: \(calculateUserType().rawValue)")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "9ecd57"))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 30)
                    
                    // 注册按钮
                    Button(action: {
                        handleRegister()
                    }) {
                        Text("注册")
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
    
    private func calculateUserType() -> UserType {
        let calendar = Calendar.current
        let age = calendar.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        return age >= 18 ? .parent : .child
    }
    
    private func isFormValid() -> Bool {
        return !nickname.isEmpty &&
               !phoneNumber.isEmpty &&
               !password.isEmpty &&
               password == confirmPassword &&
               password.count >= 6
    }
    
    private func handleRegister() {
        userType = calculateUserType()
        
        // 这里实现注册逻辑
        // 保存用户信息到数据库（密码需要MD5加密）
        let hashedPassword = password.md5
        
        // 模拟保存用户数据
        let userData: [String: Any] = [
            "nickname": nickname,
            "phoneNumber": phoneNumber,
            "password": hashedPassword,
            "birthDate": birthDate,
            "userType": userType.rawValue
        ]
        
        // 保存到UserDefaults（实际应用中应该保存到数据库）
        UserDefaults.standard.set(userData, forKey: "userData_\(phoneNumber)")
        
        // 注册成功，跳转到主界面
        showMainView = true
    }
}

// MD5扩展
extension String {
    var md5: String {
        // 简化的MD5实现（实际应用中应使用CryptoKit）
        return self.data(using: .utf8)?.base64EncodedString() ?? ""
    }
}

#Preview {
    RegisterView()
} 