//
//  uimhreachaApp.swift
//  uimhreacha
//
//  Created by Andrew Reilly on 2026-04-20.
//

import SwiftUI
import CoreData

@main
struct uimhreachaApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
