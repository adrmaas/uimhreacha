//
//  MoodView.swift
//  uimhreacha

import SwiftUI
import CoreData

struct MoodView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodLog.timestamp, ascending: false)],
        animation: .default)
    private var logs: FetchedResults<MoodLog>

    @State private var selectedRating: Int16 = 3
    @State private var saved = false

    var body: some View {
        NavigationStack {
            List {
                Section("How are you feeling?") {
                    HStack(spacing: 16) {
                        ForEach(1...5, id: \.self) { rating in
                            Button(action: { selectedRating = Int16(rating) }) {
                                VStack(spacing: 4) {
                                    Text(moodEmoji(rating))
                                        .font(.largeTitle)
                                    Text("\(rating)")
                                        .font(.caption)
                                        .foregroundStyle(selectedRating == Int16(rating) ? .primary : .secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedRating == Int16(rating) ? Color.accentColor.opacity(0.15) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)

                    Button(action: logMood) {
                        Label(saved ? "Logged!" : "Log Mood", systemImage: saved ? "checkmark.circle.fill" : "square.and.pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(saved)
                }

                Section("History") {
                    if logs.isEmpty {
                        Text("No mood logs yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(logs) { log in
                            HStack {
                                Text(moodEmoji(Int(log.rating)))
                                Text("\(log.rating)/5")
                                    .font(.headline)
                                Spacer()
                                Text(log.timestamp ?? .distantPast, formatter: moodFormatter)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: deleteLogs)
                    }
                }
            }
            .navigationTitle("Mood")
            .toolbar {
                EditButton()
            }
        }
    }

    private func logMood() {
        let log = MoodLog(context: viewContext)
        log.id = UUID()
        log.rating = selectedRating
        log.timestamp = Date()
        try? viewContext.save()
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            saved = false
        }
    }

    private func deleteLogs(offsets: IndexSet) {
        offsets.map { logs[$0] }.forEach(viewContext.delete)
        try? viewContext.save()
    }

    private func moodEmoji(_ rating: Int) -> String {
        switch rating {
        case 1: return "😞"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😄"
        default: return "😐"
        }
    }
}

private let moodFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy/MM/dd, h:mm a"
    return f
}()

#Preview {
    MoodView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
