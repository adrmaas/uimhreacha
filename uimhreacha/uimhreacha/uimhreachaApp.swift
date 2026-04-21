//
//  uimhreachaApp.swift
//  uimhreacha

import SwiftUI
import CoreData

@main
struct uimhreachaApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem { Label("Events", systemImage: "list.bullet") }
                MoodView()
                    .tabItem { Label("Mood", systemImage: "face.smiling") }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .onAppear {
                NotificationManager.requestPermissionAndSchedule()
            }
        }
    }
}
