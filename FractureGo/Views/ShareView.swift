//
//  ShareView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct ShareView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Text("ShareView")
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
    ShareView()
} 