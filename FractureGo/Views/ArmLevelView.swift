//
//  ArmLevelView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct ArmLevelView: View {
    var body: some View {
        ZStack {
            // 背景
            Color(hex: "f5f5f0").ignoresSafeArea()
            
            VStack {
                // 返回按钮
                HStack {
                    Button(action: {
                        // 返回上一级
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // 手臂训练内容
                VStack(spacing: 20) {
                    Text("手臂训练")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("选择适合的训练等级")
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    // 训练等级列表
                    VStack(spacing: 15) {
                        ForEach(1...5, id: \.self) { level in
                            Button(action: {
                                // 进入对应等级训练
                            }) {
                                HStack {
                                    Image(systemName: "figure.arms.open")
                                        .font(.title2)
                                        .foregroundColor(Color(hex: "FFB8A9"))
                                    
                                    Text("等级 \(level)")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ArmLevelView()
} 