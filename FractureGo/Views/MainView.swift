//
//  MainView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI
import CoreData

struct MainView: View {
    let persistenceController = PersistenceController.shared
    
    var body: some View {
        ContentView()
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
}

#Preview {
    MainView()
} 