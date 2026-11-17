import Foundation
import Observation

enum MissionType: String, CaseIterable, Identifiable, Codable, Sendable {
    case math
    case memory
    case photo
    case bubble
    case findDifferent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .math: return "算一道"
        case .memory: return "记色块"
        case .photo: return "拍照打卡"
        case .bubble: return "点泡泡"
        case .findDifferent: return "找不同"
        }
    }

    var symbol: String {
        switch self {
        case .math: return "number"
        case .memory: return "square.grid.2x2"
        case .photo: return "camera"
        case .bubble: return "circle.fill"
        case .findDifferent: return "sparkles"
        }
    }

    static func from(_ rawValues: [String]) -> [MissionType] {
        let mapped = rawValues.compactMap { MissionType(rawValue: $0) }
        return mapped.isEmpty ? [.math, .memory] : mapped
    }
}

@Observable
final class MissionSession: Identifiable {
    let id = UUID()
    let types: [MissionType]
    let startedAt = Date()
    var index: Int = 0
    var isFinished = false
    var completedCount = 0

    /// 由连续打卡天数推导难度：0/1 简单，2-4 中等，5+ 较难
    let difficultyLevel: Int

    init(types: [MissionType], difficultyLevel: Int) {
        self.types = types
        self.difficultyLevel = difficultyLevel
    }

    var currentType: MissionType {
        types[min(index, types.count - 1)]
    }

    var progressText: String {
        "\(min(index + 1, types.count)) / \(types.count)"
    }

    func advance() {
        completedCount += 1
        if index + 1 >= types.count {
            isFinished = true
        } else {
            index += 1
        }
    }
}
