//
//  FractureGoApp.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/17.
//

import SwiftUI

@main
struct FractureGoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}
