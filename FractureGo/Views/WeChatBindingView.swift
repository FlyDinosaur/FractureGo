//
//  WeChatBindingView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI
import CryptoKit

struct WeChatBindingView: View {
    @Environment(\.dismiss) private var dismiss
    let wechatUserInfo: WeChatUserInfo
    
    @State private var nickname = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var birthDate = Date()
    @State private var showDatePicker = false
    @State private var showMainView = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var defaultDate = Date()
    @State private var userType = "患者"
    
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
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                }
                .padding(.top, 50)
                
                // 标题
                VStack(spacing: 10) {
                    Text("绑定微信账号")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    
                    Text("完善您的个人信息")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                // 微信用户信息展示
                VStack(spacing: 10) {
                    AsyncImage(url: URL(string: wechatUserInfo.avatarUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    
                    Text("微信用户：\(wechatUserInfo.nickname)")
                        .font(.body)
                        .foregroundColor(.black)
                }
                .padding(.vertical, 10)
                
                // 表单
                VStack(spacing: 15) {
                    // 昵称输入
                    VStack(alignment: .leading, spacing: 5) {
                        Text("昵称")
                            .font(.caption)
                            .foregroundColor(.black)
                        TextField("请输入昵称", text: $nickname)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.black)
                    }
                    
                    // 手机号输入
                    VStack(alignment: .leading, spacing: 5) {
                        Text("手机号")
                            .font(.caption)
                            .foregroundColor(.black)
                        TextField("请输入手机号", text: $phoneNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                            .foregroundColor(.black)
                    }
                    
                    // 用户类型选择
                    VStack(alignment: .leading, spacing: 5) {
                        Text("用户类型")
                            .font(.caption)
                            .foregroundColor(.black)
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                userType = "患者"
                            }) {
                                HStack {
                                    Image(systemName: userType == "患者" ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(userType == "患者" ? .green : .gray)
                                    Text("患者")
                                        .foregroundColor(.black)
                                }
                            }
                            
                            Button(action: {
                                userType = "医生"
                            }) {
                                HStack {
                                    Image(systemName: userType == "医生" ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(userType == "医生" ? .green : .gray)
                                    Text("医生")
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }
                    
                    // 出生日期选择
                    VStack(alignment: .leading, spacing: 5) {
                        Text("出生日期")
                            .font(.caption)
                            .foregroundColor(.black)
                        
                        Button(action: {
                            showDatePicker = true
                        }) {
                            HStack {
                                Text(birthDate == defaultDate ? "请选择出生日期" : formatDate(birthDate))
                                    .foregroundColor(birthDate == defaultDate ? .gray : .black)
                                Spacer()
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // 绑定按钮
                Button(action: {
                    bindWeChatAccount()
                }) {
                    Text("完成绑定")
                        .foregroundColor(.white)
                        .font(.body)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.green)
                        .cornerRadius(25)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .onTapGesture {
            // 点击空白区域隐藏键盘
            hideKeyboard()
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定") { 
                if alertMessage.contains("绑定成功") {
                    // 绑定成功后通知登录成功
                    NotificationCenter.default.post(
                        name: NSNotification.Name("WeChatLoginSuccess"),
                        object: nil
                    )
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .fullScreenCover(isPresented: $showMainView) {
            MainView()
        }
        .onAppear {
            defaultDate = Date()
            // 使用微信昵称作为默认昵称
            nickname = wechatUserInfo.nickname
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerView(selectedDate: $birthDate, showDatePicker: $showDatePicker)
        }
    }
    
    // 绑定微信账号
    private func bindWeChatAccount() {
        // 输入验证
        guard !nickname.isEmpty else {
            alertMessage = "请输入昵称"
            showAlert = true
            return
        }
        
        guard !phoneNumber.isEmpty else {
            alertMessage = "请输入手机号"
            showAlert = true
            return
        }
        
        guard phoneNumber.count == 11 && phoneNumber.allSatisfy({ $0.isNumber }) else {
            alertMessage = "请输入正确的手机号"
            showAlert = true
            return
        }
        
        guard birthDate != defaultDate else {
            alertMessage = "请选择出生日期"
            showAlert = true
            return
        }
        
        // 执行绑定
        let success = UserManager.shared.bindWeChatUser(
            phoneNumber: phoneNumber,
            nickname: nickname,
            userType: userType,
            birthDate: birthDate,
            wechatUserInfo: wechatUserInfo
        )
        
        if success {
            alertMessage = "微信账号绑定成功！"
            showAlert = true
        } else {
            alertMessage = "该手机号已被使用，请更换手机号"
            showAlert = true
        }
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
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
    WeChatBindingView(wechatUserInfo: WeChatUserInfo(openId: "mock_wechat_openid_1234", nickname: "微信用户123", avatarUrl: "https://example.com/avatar.jpg", unionId: nil))
} 