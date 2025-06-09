//
//  FitZoneApp.swift
//  FitZone
//
//  Created by User on 09/06/2025.
//

import SwiftUI

@main
struct FitZoneApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
