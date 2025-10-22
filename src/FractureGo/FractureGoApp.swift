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
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onOpenURL { url in
                    // 处理微信回调
                    _ = WeChatManager.shared.handleOpenURL(url)
                }
        }
    }
}
