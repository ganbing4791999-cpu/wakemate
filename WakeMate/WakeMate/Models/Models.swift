import Foundation
import SwiftData

@Model
final class AlarmItem: Identifiable {
    @Attribute(.unique) var id: UUID
    var hour: Int
    var minute: Int
    /// 1 = 周日, 2 = 周一 ... 7 = 周六
    var weekdays: [Int]
    var label: String
    var characterID: String
    var missionTypes: [String]
    var isEnabled: Bool
    /// AlarmKit 主响铃 + 备份响铃的 ID，完成任务后统一取消
    var ringIDs: [String]

    init(
        id: UUID = UUID(),
        hour: Int = 7,
        minute: Int = 0,
        weekdays: [Int] = [2, 3, 4, 5, 6],
        label: String = "起床",
        characterID: String = "pico",
        missionTypes: [String] = ["math", "memory"],
        isEnabled: Bool = true,
        ringIDs: [String] = []
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.label = label
        self.characterID = characterID
        self.missionTypes = missionTypes
        self.isEnabled = isEnabled
        self.ringIDs = ringIDs
    }

    var displayTime: String {
        String(format: "%02d:%02d", hour, minute)
    }

    var weekdayText: String {
        let names = ["", "日", "一", "二", "三", "四", "五", "六"]
        let sorted = weekdays.sorted()
        if sorted == [2, 3, 4, 5, 6] { return "周一至周五" }
        if sorted.count == 7 { return "每天" }
        if sorted.isEmpty { return "仅一次" }
        return "周" + sorted.map { names[$0] }.joined(separator: "、")
    }
}

enum WakeStatus: String, Codable, Sendable {
    case completed
    case skipped
}

@Model
final class WakeRecord {
    var date: Date
    var statusRaw: String
    var missionCount: Int
    var duration: TimeInterval

    init(date: Date = Date(), status: WakeStatus, missionCount: Int, duration: TimeInterval) {
        self.date = date
        self.statusRaw = status.rawValue
        self.missionCount = missionCount
        self.duration = duration
    }

    var status: WakeStatus {
        WakeStatus(rawValue: statusRaw) ?? .skipped
    }
}

@Model
final class Streak {
    var current: Int
    var best: Int
    var lastCompletionDay: Date?

    init(current: Int = 0, best: Int = 0, lastCompletionDay: Date? = nil) {
        self.current = current
        self.best = best
        self.lastCompletionDay = lastCompletionDay
    }
}
