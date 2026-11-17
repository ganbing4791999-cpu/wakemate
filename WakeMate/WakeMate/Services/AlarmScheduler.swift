import Foundation
import SwiftUI
import AlarmKit
import AppIntents

struct WakeMetadata: AlarmMetadata, Codable, Sendable, Equatable {
    var label: String
    var characterID: String
}

enum AlarmSchedulerError: LocalizedError {
    case denied

    var errorDescription: String? {
        "没有获得闹钟权限，请在系统设置中允许醒伴设置闹钟。"
    }
}

/// 负责把闹钟注册进 iOS 系统。
/// 关键策略：一次起床注册「主响铃 + 多个备份响铃」。
/// 系统 Stop 按钮无法隐藏，也无法百分百依赖 StopIntent 回调；
/// 因此按掉主响铃后，备份响铃会继续把人叫醒，只有完成晨间任务才取消全部。
@MainActor
final class AlarmScheduler {
    static let shared = AlarmScheduler()

    private let manager = AlarmManager.shared
    private let backupOffsets: [TimeInterval] = [60, 180, 300, 420]

    func requestAuthorization() async throws -> Bool {
        switch manager.authorizationState {
        case .authorized:
            return true
        case .denied:
            return false
        default:
            let state = try await manager.requestAuthorization()
            switch state {
            case .authorized: return true
            case .denied, .notDetermined: return false
            @unknown default: return false
            }
        }
    }

    func schedule(item: AlarmItem) async throws {
        guard try await requestAuthorization() else {
            throw AlarmSchedulerError.denied
        }

        await cancel(item: item)

        let base = nextFireDate(for: item)
        var ids: [String] = []

        for (index, offset) in ([0] + backupOffsets).enumerated() {
            let id = UUID()
            let fireDate = base.addingTimeInterval(offset)
            try await scheduleOne(id: id, date: fireDate, item: item, isPrimary: index == 0)
            ids.append(id.uuidString)
        }

        item.ringIDs = ids
    }

    func cancel(item: AlarmItem) async {
        for raw in item.ringIDs {
            guard let id = UUID(uuidString: raw) else { continue }
            try? await manager.cancel(id: id)
        }
        item.ringIDs = []
    }

    func cancelAll(items: [AlarmItem]) async {
        for item in items {
            await cancel(item: item)
        }
    }

    /// 由「开始任务」按钮的 Intent 调用：只停掉当前这一声，备份响铃仍然保留。
    func stopRing(id rawID: String) async {
        guard let id = UUID(uuidString: rawID) else { return }
        try? await manager.stop(id: id)
    }

    /// 只有任务全部完成后才调用：取消主响铃和所有备份响铃。
    func finish(item: AlarmItem) async {
        await cancel(item: item)
    }

    private func scheduleOne(
        id: UUID,
        date: Date,
        item: AlarmItem,
        isPrimary: Bool
    ) async throws {
        let title = isPrimary
            ? "\(item.characterName) 叫你起床 · \(item.label)"
            : "醒伴备份响铃 · \(item.label)"

        let alert = AlarmPresentation.Alert(
            title: title,
            secondaryButton: AlarmButton(
                text: "开始任务",
                textColor: .white,
                systemImageName: "checkmark.circle"
            ),
            secondaryButtonBehavior: .custom
        )

        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(alert: alert),
            metadata: WakeMetadata(label: item.label, characterID: item.characterID),
            tintColor: isPrimary ? Color.indigo : Color.orange
        )

        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(date),
            attributes: attributes,
            stopIntent: nil,
            secondaryIntent: OpenMissionIntent(alarmID: item.id.uuidString),
            sound: .default
        )

        try await manager.schedule(id: id, configuration: configuration)
    }

    private func nextFireDate(for item: AlarmItem) -> Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = item.hour
        components.minute = item.minute
        components.second = 0

        guard var date = calendar.date(from: components) else { return now }

        if item.weekdays.isEmpty {
            if date <= now {
                date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            }
            return date
        }

        var guardCount = 0
        while (date <= now || !item.weekdays.contains(calendar.component(.weekday, from: date))) && guardCount < 14 {
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            guardCount += 1
        }
        return date
    }
}

extension AlarmItem {
    var characterName: String {
        switch characterID {
        case "pico": return "小鸡哔哔"
        case "cheeze": return "仓鼠起司"
        case "bready": return "面包君"
        default: return "醒伴"
        }
    }
}
