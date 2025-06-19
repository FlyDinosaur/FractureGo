//
//  RegisterView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI
import CryptoKit

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var nickname = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var birthDate = Date()
    @State private var showDatePicker = false
    @State private var showMainView = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // 背景
            Color(hex: "f5f5f0").ignoresSafeArea()
            
            // 顶部波浪遮挡
            TopBlurView()
            
            VStack(spacing: 30) {
                // 返回按钮
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 注册表单
                VStack(spacing: 25) {
                    Text("创建账户")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    
                    VStack(spacing: 15) {
                        // 昵称输入框
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            TextField("昵称", text: $nickname)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        // 手机号输入框
                        HStack {
                            Image(systemName: "phone")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            TextField("手机号", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        // 密码输入框
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            SecureField("密码", text: $password)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        // 确认密码输入框
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            SecureField("确认密码", text: $confirmPassword)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        // 出生日期选择
                        Button(action: {
                            showDatePicker = true
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                if showDatePicker || birthDate != Date() {
                                    Text(formatDate(birthDate))
                                        .foregroundColor(.black)
                                } else {
                                    Text("选择出生日期")
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .sheet(isPresented: $showDatePicker) {
                            DatePickerView(selectedDate: $birthDate, showDatePicker: $showDatePicker)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // 注册按钮
                    Button(action: {
                        registerUser()
                    }) {
                        Text("注册")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "9ecd57"))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 30)
                    .disabled(nickname.isEmpty || phoneNumber.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                    .opacity(nickname.isEmpty || phoneNumber.isEmpty || password.isEmpty || confirmPassword.isEmpty ? 0.6 : 1.0)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .alert("提示", isPresented: $showAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
        .fullScreenCover(isPresented: $showMainView) {
            MainView()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    private func registerUser() {
        // 验证输入
        guard validateInput() else { return }
        
        // 根据出生日期判断用户类型
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        let userType = age >= 18 ? "家长" : "儿童"
        
        // MD5加密密码
        let encryptedPassword = md5Hash(password)
        
        // 保存用户数据
        let userData: [String: Any] = [
            "nickname": nickname,
            "phoneNumber": phoneNumber,
            "password": encryptedPassword,
            "birthDate": birthDate.timeIntervalSince1970,
            "userType": userType,
            "isWeChatUser": false
        ]
        
        UserDefaults.standard.set(userData, forKey: "userData_\(phoneNumber)")
        
        // 设置当前用户
        UserManager.shared.loginUser(phoneNumber: phoneNumber, userData: userData)
        
        showMainView = true
    }
    
    private func validateInput() -> Bool {
        if nickname.isEmpty {
            alertMessage = "请输入昵称"
            showAlert = true
            return false
        }
        
        if phoneNumber.isEmpty || phoneNumber.count != 11 {
            alertMessage = "请输入正确的手机号"
            showAlert = true
            return false
        }
        
        if password.isEmpty || password.count < 6 {
            alertMessage = "密码至少6位"
            showAlert = true
            return false
        }
        
        if password != confirmPassword {
            alertMessage = "两次密码输入不一致"
            showAlert = true
            return false
        }
        
        // 检查手机号是否已存在
        if UserDefaults.standard.dictionary(forKey: "userData_\(phoneNumber)") != nil {
            alertMessage = "该手机号已注册"
            showAlert = true
            return false
        }
        
        return true
    }
    
    private func md5Hash(_ string: String) -> String {
        let digest = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var showDatePicker: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("选择出生日期", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .padding()
                
                Spacer()
            }
            .navigationTitle("选择出生日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showDatePicker = false
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showDatePicker = false
                    }
                }
            }
        }
    }
}

#Preview {
    RegisterView()
} 