import AppIntents
import AlarmKit
import Foundation

/// 系统闹钟副按钮：打开 App 进入任务页。
/// 重要：自定义按钮不会自动停铃，必须在这里先停掉当前这一声，
/// 备份响铃保留，直到任务真正完成才全部取消。
struct OpenMissionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "开始晨间任务"
    static var description = IntentDescription("打开醒伴，完成起床任务")
    static var openAppWhenRun = true

    @Parameter(title: "闹钟标识")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(true, forKey: MissionLaunchKeys.pending)
        UserDefaults.standard.set(alarmID, forKey: MissionLaunchKeys.alarmID)

        if let id = UUID(uuidString: alarmID) {
            try? await AlarmManager.shared.stop(id: id)
        }

        return .result()
    }
}

enum MissionLaunchKeys {
    static let pending = "wakemate.pendingMission"
    static let alarmID = "wakemate.pendingAlarmID"
}
