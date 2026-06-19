import SwiftUI

@main
struct RivetApp: App {
    @State private var services = AppServices.live()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(services)
                .preferredColorScheme(services.settings.theme.preferredScheme)
        }
    }
}

@MainActor
@Observable
public final class AppServices {
    public var settings: SettingsStore
    public var sync: SyncService
    public var notifications: NotificationScheduler
    public var timeline: TimelineStore

    init(settings: SettingsStore, sync: SyncService, notifications: NotificationScheduler, timeline: TimelineStore) {
        self.settings = settings
        self.sync = sync
        self.notifications = notifications
        self.timeline = timeline
    }

    static func live() -> AppServices {
        let settings = SettingsStore()
        let api = APIClient(configuration: .release)
        let timeline = TimelineStore()
        let notifications = NotificationScheduler()
        let sync = SyncService(api: api, timeline: timeline, settings: settings, notifications: notifications)
        return AppServices(settings: settings, sync: sync, notifications: notifications, timeline: timeline)
    }
}
