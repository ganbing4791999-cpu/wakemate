import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @Query private var alarms: [AlarmItem]
    @Query private var streaks: [Streak]

    @State private var missionSession: MissionSession?

    var body: some View {
        TabView {
            AlarmListView()
                .tabItem { Label("闹钟", systemImage: "alarm.fill") }

            CharacterView()
                .tabItem { Label("角色", systemImage: "face.smiling") }

            RecordView()
                .tabItem { Label("记录", systemImage: "chart.bar.fill") }
        }
        .onAppear(perform: checkPendingMission)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { checkPendingMission() }
        }
        .fullScreenCover(item: $missionSession) { session in
            MissionContainerView(session: session) {
                Task { await complete(session) }
            }
        }
    }

    private func checkPendingMission() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: MissionLaunchKeys.pending) else { return }

        let alarmID = defaults.string(forKey: MissionLaunchKeys.alarmID) ?? ""
        guard let alarm = alarms.first(where: { $0.id.uuidString == alarmID }) else {
            clearPending()
            return
        }

        appState.activeAlarmID = alarmID
        appState.showMission = true

        let current = streaks.first?.current ?? 0
        let level = current >= 5 ? 5 : (current >= 2 ? 3 : 1)
        missionSession = MissionSession(
            types: MissionType.from(alarm.missionTypes),
            difficultyLevel: level
        )

        clearPending()
    }

    private func complete(_ session: MissionSession) async {
        if let rawID = appState.activeAlarmID,
           let alarm = alarms.first(where: { $0.id.uuidString == rawID }) {
            await AlarmScheduler.shared.finish(item: alarm)
        }

        let record = WakeRecord(
            status: .completed,
            missionCount: session.completedCount,
            duration: Date().timeIntervalSince(session.startedAt)
        )
        context.insert(record)
        updateStreak()

        appState.activeAlarmID = nil
        appState.showMission = false
        missionSession = nil
    }

    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let streak = streaks.first ?? Streak()

        if let last = streak.lastCompletionDay {
            let lastDay = calendar.startOfDay(for: last)
            if calendar.isDate(lastDay, equalTo: today, in: .day) {
                // 同一天完成多次，不重复加
            } else if let next = calendar.date(byAdding: .day, value: 1, to: lastDay),
                      calendar.isDate(next, equalTo: today, in: .day) {
                streak.current += 1
            } else {
                streak.current = 1
            }
        } else {
            streak.current = 1
        }

        streak.best = max(streak.best, streak.current)
        streak.lastCompletionDay = Date()

        if streaks.isEmpty {
            context.insert(streak)
        }
    }

    private func clearPending() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: MissionLaunchKeys.pending)
        defaults.removeObject(forKey: MissionLaunchKeys.alarmID)
    }
}
