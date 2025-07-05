//
//  MyView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct MyView: View {
    @State private var showMLTest = false
    
    var body: some View {
        VStack {
            // 顶部空白区域 - 为TopBlurView预留空间
            Spacer()
                .frame(height: 80)
            
            Spacer()
            
            Text("我的")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Spacer()
                .frame(height: 40)
            
            // ML测试按钮
            Button(action: {
                showMLTest = true
            }) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                    Text("ML服务测试")
                        .font(.title3)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(Color.blue)
                .cornerRadius(25)
                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .fullScreenCover(isPresented: $showMLTest) {
                MLTestView()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "f5f5f0"))
        .navigationBarHidden(true)
    }
}

#Preview {
    MyView()
}