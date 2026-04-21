//
//  Persistence.swift
//  uimhreacha

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let ctx = result.container.viewContext
        let type1 = EventType(context: ctx)
        type1.id = UUID()
        type1.name = "Water"
        type1.createdAt = Date()
        let log = EventLog(context: ctx)
        log.id = UUID()
        log.timestamp = Date()
        log.eventType = type1
        try? ctx.save()
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "uimhreacha")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
