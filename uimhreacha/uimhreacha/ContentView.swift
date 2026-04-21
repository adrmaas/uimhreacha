//
//  ContentView.swift
//  uimhreacha

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EventType.createdAt, ascending: true)],
        animation: .default)
    private var eventTypes: FetchedResults<EventType>

    @State private var showingAddType = false
    @State private var newTypeName = ""

    @State private var selectedEventType: EventType?

    var body: some View {
        NavigationStack {
            List {
                ForEach(eventTypes) { eventType in
                    EventTypeRow(eventType: eventType)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedEventType = eventType }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewContext.delete(eventType)
                                try? viewContext.save()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .navigationTitle("Log Events")
            .navigationDestination(item: $selectedEventType) { eventType in
                EventDetailView(eventType: eventType)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingAddType = true }) {
                        Label("Add Event Type", systemImage: "plus")
                    }
                }
            }
            .alert("New Event Type", isPresented: $showingAddType) {
                TextField("Name", text: $newTypeName)
                Button("Add") { addEventType() }
                Button("Cancel", role: .cancel) { newTypeName = "" }
            }

        }
    }

    private func addEventType() {
        guard !newTypeName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let et = EventType(context: viewContext)
        et.id = UUID()
        et.name = newTypeName.trimmingCharacters(in: .whitespaces)
        et.createdAt = Date()
        try? viewContext.save()
        newTypeName = ""
    }
}

struct EventTypeRow: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var eventType: EventType

    var logCount: Int {
        (eventType.logs as? Set<EventLog>)?.count ?? 0
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(eventType.name ?? "Unnamed")
                    .font(.headline)
                Text("\(logCount) log\(logCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: logEvent) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
        }
    }

    private func logEvent() {
        let log = EventLog(context: viewContext)
        log.id = UUID()
        log.timestamp = Date()
        log.eventType = eventType
        try? viewContext.save()
    }
}

struct EventDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var eventType: EventType

    var logs: [EventLog] {
        let set = eventType.logs as? Set<EventLog> ?? []
        return set.sorted { ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast) }
    }

    var body: some View {
        List {
            Section("History") {
                if logs.isEmpty {
                    Text("No logs yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(logs) { log in
                        Text(log.timestamp ?? .distantPast, formatter: logFormatter)
                            .foregroundStyle(.secondary)
                    }
                    .onDelete(perform: deleteLogs)
                }
            }
        }
        .navigationTitle(eventType.name ?? "Event")
        .toolbar {
            EditButton()
        }
    }

    private func deleteLogs(offsets: IndexSet) {
        offsets.map { logs[$0] }.forEach(viewContext.delete)
        try? viewContext.save()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

private let logFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy/MM/dd, h:mm a"
    return f
}()
