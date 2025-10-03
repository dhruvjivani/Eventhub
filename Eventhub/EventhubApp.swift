//
//  EventhubApp.swift
//  Eventhub
//
//  Created by Dhruv Rasikbhai Jivani on 10/2/25.
//

import SwiftUI
import CoreData

@main
struct EventhubApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
