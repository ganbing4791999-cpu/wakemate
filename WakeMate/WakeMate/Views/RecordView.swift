import SwiftUI
import SwiftData

struct RecordView: View {
    @Query(sort: \WakeRecord.date, order: .reverse) private var records: [WakeRecord]
    @Query private var streaks: [Streak]

    private var streak: Streak? { streaks.first }

    var body: some View {
        NavigationStack {
            List {
                Section("连续起床") {
                    HStack(spacing: 24) {
                        StatBlock(title: "当前", value: "\(streak?.current ?? 0)", color: .indigo)
                        StatBlock(title: "最佳", value: "\(streak?.best ?? 0)", color: .orange)
                        StatBlock(title: "累计完成", value: "\(records.filter { $0.status == .completed }.count)", color: .green)
                    }
                    .frame(minHeight: 90)
                }

                Section("最近记录") {
                    if records.isEmpty {
                        Text("还没有记录，完成一次晨间任务就会出现在这里。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(minHeight: 60)
                    } else {
                        ForEach(records.prefix(30)) { record in
                            HStack {
                                Image(systemName: record.status == .completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(record.status == .completed ? .green : .red)
                                VStack(alignment: .leading) {
                                    Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                    Text("完成 \(record.missionCount) 项 · 用时 \(Int(record.duration)) 秒")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(minHeight: 56)
                        }
                    }
                }
            }
            .navigationTitle("记录")
        }
    }
}

private struct StatBlock: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("\(title) \(value)")
    }
}
