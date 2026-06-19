import Foundation
import UserNotifications

@MainActor
@Observable
public final class NotificationScheduler {
    public var pendingCount: Int = 0
    public var permissionStatus: UNAuthorizationStatus = .notDetermined

    public func requestPermission() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await refreshPermission()
        } catch {
            await refreshPermission()
        }
    }

    public func refreshPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionStatus = settings.authorizationStatus
    }

    public func refreshNext48Hours(settings: AppSettings, window: ProgressWindow?) async {
        guard settings.notificationsEnabled else { return }
        await refreshPermission()
        guard permissionStatus == .authorized || permissionStatus == .provisional else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rivet-briefing-fallback", "rivet-checkin-fallback"])
        schedule(identifier: "rivet-briefing-fallback", title: "Rivet", body: "Your briefing is ready.", at: nextDate(settings.morningTimeLocal))
        schedule(identifier: "rivet-checkin-fallback", title: "Rivet", body: "Time to log what actually moved.", at: nextDate(settings.eveningTimeLocal))
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        pendingCount = requests.count
    }

    private func schedule(identifier: String, title: String, body: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date), repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    private func nextDate(_ hhmm: String) -> Date {
        let parts = hhmm.split(separator: ":").compactMap(Int.init)
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = parts.first ?? 9
        components.minute = parts.dropFirst().first ?? 0
        let candidate = Calendar.current.date(from: components) ?? Date()
        return candidate > Date() ? candidate : Calendar.current.date(byAdding: .day, value: 1, to: candidate) ?? candidate
    }
}
