import SwiftUI
import SwiftData

@main
struct WakeMateApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(appState)
        }
        .modelContainer(for: [AlarmItem.self, WakeRecord.self, Streak.self])
    }
}
