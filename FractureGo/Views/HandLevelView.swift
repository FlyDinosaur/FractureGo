//
//  HandLevelView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct HandLevelView: View {
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
                
                // 手部训练内容
                VStack(spacing: 20) {
                    Text("手部训练")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "B8A9FF"))
                    
                    Text("Hand Training")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Image(systemName: "hand.raised")
                        .font(.system(size: 100))
                        .foregroundColor(Color(hex: "B8A9FF"))
                    
                    Text("选择训练关卡")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    HandLevelView()
} 