import SwiftUI

enum AppTab: Hashable, CaseIterable, Identifiable {
    case today
    case settings

    var id: Self { self }
}

@MainActor
@Observable
final class RouterPath {
    var path: [Route] = []
    var presentedSheet: SheetDestination?
}

enum Route: Hashable {
    case diagnostics
    case notificationExplanation
}

enum SheetDestination: Identifiable, Hashable {
    case monthlyCalendar

    var id: String { "monthlyCalendar" }
}

public struct AppRootView: View {
    @Environment(AppServices.self) private var services
    @State private var selectedTab: AppTab = .today
    @State private var router = RouterPath()

    public init() {}

    public var body: some View {
        Group {
            if services.settings.pairingState == .paired {
                TabView(selection: $selectedTab) {
                    NavigationStack(path: $router.path) {
                        TodayView()
                            .navigationDestination(for: Route.self) { route in
                                switch route {
                                case .diagnostics:
                                    DiagnosticsView()
                                case .notificationExplanation:
                                    NotificationPermissionView()
                                }
                            }
                    }
                    .environment(router)
                    .tabItem { Label("Today", systemImage: "calendar.day.timeline.left") }
                    .tag(AppTab.today)

                    NavigationStack {
                        SettingsView()
                    }
                    .environment(router)
                    .tabItem { Label("Settings", systemImage: "gear") }
                    .tag(AppTab.settings)
                }
                .sheet(item: $router.presentedSheet) { sheet in
                    switch sheet {
                    case .monthlyCalendar:
                        MonthlyCalendarView()
                    }
                }
            } else {
                OnboardingPairingView()
            }
        }
        .tint(RivetTheme.accent)
        .background(RivetTheme.background)
        .task {
            await services.sync.sync(reason: "launch")
        }
    }
}
