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