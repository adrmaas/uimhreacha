//
//  NotificationManager.swift
//  uimhreacha

import UserNotifications

struct NotificationManager {
    static func requestPermissionAndSchedule() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            scheduleDaily()
        }
    }

    static func scheduleDaily() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["mood.morning", "mood.afternoon", "mood.evening"])

        let notifications: [(id: String, hour: Int, title: String)] = [
            ("mood.morning",   8,  "Good morning! How are you feeling?"),
            ("mood.afternoon", 13, "Afternoon check-in — how's your mood?"),
            ("mood.evening",   20, "Evening check-in — how are you feeling?"),
        ]

        let content = UNMutableNotificationContent()
        content.sound = .default

        for item in notifications {
            let c = UNMutableNotificationContent()
            c.title = "Mood Check-in"
            c.body = item.title
            c.sound = .default

            var components = DateComponents()
            components.hour = item.hour
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: item.id, content: c, trigger: trigger)
            center.add(request)
        }
    }
}
