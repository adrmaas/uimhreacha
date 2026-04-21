//
//  InsightsView.swift
//  uimhreacha

import SwiftUI
import Charts
import CoreData

enum InsightsPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }

    var unit: Calendar.Component {
        switch self {
        case .week: return .day
        case .month: return .day
        case .quarter: return .weekOfYear
        case .year: return .month
        }
    }

    var axisFormat: Date.FormatStyle {
        switch self {
        case .week: return .dateTime.day().month(.abbreviated)
        case .month: return .dateTime.day().month(.abbreviated)
        case .quarter: return .dateTime.week()
        case .year: return .dateTime.month(.abbreviated)
        }
    }
}

struct MoodPoint: Identifiable {
    let id = UUID()
    let date: Date
    let avg: Double
}

struct EventPoint: Identifiable {
    let id = UUID()
    let date: Date
    let name: String
    let count: Int
}

struct InsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \MoodLog.timestamp, ascending: true)])
    private var moodLogs: FetchedResults<MoodLog>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \EventLog.timestamp, ascending: true)])
    private var eventLogs: FetchedResults<EventLog>

    @State private var period: InsightsPeriod = .week
    @State private var scrollPosition = ScrollPosition(edge: .leading)

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal
    }

    private var startDate: Date {
        switch period {
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        case .month:
            return calendar.dateInterval(of: .month, for: .now)?.start ?? .now
        case .quarter:
            let month = calendar.component(.month, from: .now)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var comps = calendar.dateComponents([.year], from: .now)
            comps.month = quarterStartMonth
            comps.day = 1
            return calendar.date(from: comps) ?? .now
        case .year:
            return calendar.dateInterval(of: .year, for: .now)?.start ?? .now
        }
    }

    private var endDate: Date {
        switch period {
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: .now)?.end ?? .now
        case .month:
            return calendar.dateInterval(of: .month, for: .now)?.end ?? .now
        case .quarter:
            return calendar.date(byAdding: .month, value: 3, to: startDate) ?? .now
        case .year:
            return calendar.dateInterval(of: .year, for: .now)?.end ?? .now
        }
    }

    private var moodPoints: [MoodPoint] {
        let filtered = moodLogs.filter { ($0.timestamp ?? .distantPast) >= startDate }
        let grouped = Dictionary(grouping: filtered) {
            calendar.dateInterval(of: period.unit, for: $0.timestamp ?? .now)?.start ?? .now
        }
        return grouped.map { date, logs in
            let avg = Double(logs.map { Int($0.rating) }.reduce(0, +)) / Double(logs.count)
            return MoodPoint(date: date, avg: avg)
        }.sorted { $0.date < $1.date }
    }

    private var eventPoints: [EventPoint] {
        let filtered = eventLogs.filter { ($0.timestamp ?? .distantPast) >= startDate }
        struct Key: Hashable { let date: Date; let name: String }
        let grouped = Dictionary(grouping: filtered) { log -> Key in
            let bucket = calendar.dateInterval(of: period.unit, for: log.timestamp ?? .now)?.start ?? .now
            return Key(date: bucket, name: log.eventType?.name ?? "Unknown")
        }
        return grouped.map { key, logs in
            EventPoint(date: key.date, name: key.name, count: logs.count)
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Period", selection: $period) {
                        ForEach(InsightsPeriod.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color.clear)

                Section("Mood & Events") {
                    if moodPoints.isEmpty && eventPoints.isEmpty {
                        Text("No data for this period")
                            .foregroundStyle(.secondary)
                    } else {
                        let bucketCount: Int = {
                            switch period {
                            case .week: return 7
                            case .month:
                                return calendar.range(of: .day, in: .month, for: .now)?.count ?? 30
                            case .quarter: return 13
                            case .year: return 12
                            }
                        }()
                        let chartWidth = CGFloat(bucketCount) * 44

                        let totalDuration = endDate.timeIntervalSince(startDate)
                        let todayOffset = Date.now.timeIntervalSince(startDate)
                        let todayFraction = max(0, min(1, todayOffset / totalDuration))
                        let centeredX = max(0, CGFloat(todayFraction) * chartWidth - 160)

                        ScrollView(.horizontal) {
                            Chart {
                                ForEach(eventPoints) { point in
                                    BarMark(
                                        x: .value("Date", point.date, unit: period.unit),
                                        y: .value("Count", point.count)
                                    )
                                    .foregroundStyle(by: .value("Event", point.name))
                                    .opacity(0.75)
                                }
                                ForEach(moodPoints) { point in
                                    LineMark(
                                        x: .value("Date", point.date, unit: period.unit),
                                        y: .value("Mood", point.avg),
                                        series: .value("Series", "Mood")
                                    )
                                    .foregroundStyle(.orange)
                                    PointMark(
                                        x: .value("Date", point.date, unit: period.unit),
                                        y: .value("Mood", point.avg)
                                    )
                                    .foregroundStyle(.orange)
                                }
                            }
                            .chartXScale(domain: startDate...endDate)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: period.unit)) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel(format: period.axisFormat, centered: true)
                                }
                            }
                            .frame(width: chartWidth, height: 240)
                        }
                        .scrollPosition($scrollPosition)
                        .onAppear { scrollPosition = ScrollPosition(x: centeredX) }
                        .onChange(of: period) { scrollPosition = ScrollPosition(x: centeredX) }
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }
}

#Preview {
    InsightsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
