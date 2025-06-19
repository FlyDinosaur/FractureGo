//
//  RegisterView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI
import CryptoKit

struct RegisterView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var nickname = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var birthDate = Date()
    @State private var defaultDate = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showDatePicker = false
    @State private var showAccountLogin = false // 注册成功后显示账号登录界面
    
    var body: some View {
        ZStack {
            // 背景
            Color(hex: "f5f5f0").ignoresSafeArea()
            
            // 顶部波浪遮挡
            TopBlurView()
            
            VStack(spacing: 20) {
                // 返回按钮
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color(hex: "9ecd57")) // 绿色，背景为白色的反色
                    }
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                Spacer()
                    .frame(height: 20)
                
                // 注册表单
                VStack(spacing: 25) {
                    Text("注册账号")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    
                    VStack(spacing: 15) {
                        // 昵称输入框
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(.black.opacity(0.7))
                                .frame(width: 20)
                            TextField("", text: $nickname, prompt: Text("昵称").foregroundColor(.black.opacity(0.6)))
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                        
                        // 手机号输入框
                        HStack {
                            Image(systemName: "phone")
                                .foregroundColor(.black.opacity(0.7))
                                .frame(width: 20)
                            TextField("", text: $phoneNumber, prompt: Text("手机号").foregroundColor(.black.opacity(0.6)))
                                .keyboardType(.phonePad)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                        
                        // 密码输入框
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.black.opacity(0.7))
                                .frame(width: 20)
                            SecureField("", text: $password, prompt: Text("密码(至少6位)").foregroundColor(.black.opacity(0.6)))
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                        
                        // 确认密码输入框
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.black.opacity(0.7))
                                .frame(width: 20)
                            SecureField("", text: $confirmPassword, prompt: Text("确认密码").foregroundColor(.black.opacity(0.6)))
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                        
                        // 出生日期选择
                        Button(action: {
                            showDatePicker = true
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.black.opacity(0.7))
                                    .frame(width: 20)
                                if hasSelectedDate() {
                                    Text(formatDate(birthDate))
                                        .foregroundColor(.black)
                                } else {
                                    Text("选择出生日期")
                                        .foregroundColor(.black.opacity(0.5))
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.black.opacity(0.7))
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .sheet(isPresented: $showDatePicker) {
                            DatePickerView(selectedDate: $birthDate, showDatePicker: $showDatePicker)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // 注册按钮
                    Button(action: {
                        print("注册按钮被点击") // 添加调试信息
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
                    // 简化disabled条件，只检查基本字段
                    .disabled(nickname.isEmpty || phoneNumber.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                    .opacity(nickname.isEmpty || phoneNumber.isEmpty || password.isEmpty || confirmPassword.isEmpty ? 0.6 : 1.0)
                }
                
                Spacer()
                    .frame(height: 60)
            }
        }
        .navigationBarHidden(true)
        .onTapGesture {
            // 点击空白区域隐藏键盘
            hideKeyboard()
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定") { 
                // 如果是注册成功的提示，点击确定后跳转到账号登录界面
                if alertMessage == "注册成功！请返回登录页面进行登录。" {
                    showAccountLogin = true
                }
            }
        } message: {
            Text(alertMessage)
        }
        .fullScreenCover(isPresented: $showAccountLogin) {
            AccountLoginView()
        }
        .onAppear {
            defaultDate = Date()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    private func hasSelectedDate() -> Bool {
        return Calendar.current.dateComponents([.year, .month, .day], from: birthDate) != 
               Calendar.current.dateComponents([.year, .month, .day], from: defaultDate)
    }
    
    private func registerUser() {
        print("registerUser方法被调用")
        
        // 验证输入
        guard validateInput() else { 
            print("验证失败，返回")
            return 
        }
        
        print("验证通过，开始注册流程")
        
        // 根据出生日期判断用户类型
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        let userType = age >= 18 ? "家长" : "儿童"
        
        // MD5加密密码 - 使用String扩展的md5属性
        let encryptedPassword = password.md5
        
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
        
        print("注册成功，准备返回登录界面")
        alertMessage = "注册成功！请返回登录页面进行登录。"
        showAlert = true
    }
    
    private func validateInput() -> Bool {
        print("开始验证输入")
        
        if nickname.isEmpty {
            print("昵称为空")
            alertMessage = "请输入昵称"
            showAlert = true
            return false
        }
        
        if phoneNumber.isEmpty {
            print("手机号为空")
            alertMessage = "请输入手机号"
            showAlert = true
            return false
        }
        
        if !isValidPhoneNumber(phoneNumber) {
            print("手机号格式不正确")
            alertMessage = "请输入正确的手机号"
            showAlert = true
            return false
        }
        
        // 检查手机号是否已经注册
        if UserDefaults.standard.dictionary(forKey: "userData_\(phoneNumber)") != nil {
            print("手机号已经注册")
            alertMessage = "该手机号已经注册，请直接登录"
            showAlert = true
            return false
        }
        
        if password.isEmpty || password.count < 6 {
            print("密码无效，长度: \(password.count)")
            alertMessage = "密码至少6位"
            showAlert = true
            return false
        }
        
        if password != confirmPassword {
            print("密码不一致")
            alertMessage = "两次密码输入不一致"
            showAlert = true
            return false
        }
        
        print("基本验证通过")
        return true
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = "^1[3-9]\\d{9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
}



#Preview {
    RegisterView()
} 