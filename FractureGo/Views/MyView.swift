//
//  MyView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct MyView: View {
    var body: some View {
        VStack {
            // 顶部空白区域 - 为TopBlurView预留空间
            Spacer()
                .frame(height: 80)
            
            Spacer()
            
            Text("MyView")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
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