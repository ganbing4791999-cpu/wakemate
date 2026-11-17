import SwiftUI
import SwiftData

struct AlarmListView: View {
    @Query(sort: \AlarmItem.hour) private var alarms: [AlarmItem]
    @Environment(\.modelContext) private var context
    @State private var editing: AlarmItem?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if alarms.isEmpty {
                    ContentUnavailableView(
                        "还没有闹钟",
                        systemImage: "alarm",
                        description: Text("点右上角添加第一个闹钟")
                    )
                }

                ForEach(alarms) { alarm in
                    Button {
                        editing = alarm
                    } label: {
                        HStack(spacing: 14) {
                            Text(alarm.displayTime)
                                .font(.system(size: 32, weight: .semibold, design: .rounded))
                                .accessibilityLabel("闹钟时间 \(alarm.displayTime)")

                            VStack(alignment: .leading, spacing: 2) {
                                Text(alarm.label).font(.headline)
                                Text(alarm.weekdayText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(alarm.missionTypes.compactMap { MissionType(rawValue: $0)?.title }.joined(separator: " + "))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }

                            Spacer()

                            Image(systemName: alarm.isEnabled ? "alarm.fill" : "alarm")
                                .foregroundStyle(alarm.isEnabled ? .indigo : .secondary)
                        }
                        .contentShape(Rectangle())
                        .frame(minHeight: 64)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await AlarmScheduler.shared.cancel(item: alarm) }
                            context.delete(alarm)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("闹钟")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let item = AlarmItem()
                        context.insert(item)
                        editing = item
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("添加闹钟")
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
            .sheet(item: $editing) { item in
                AlarmEditView(alarm: item, errorMessage: $errorMessage)
            }
            .alert("提示", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
}

private struct AlarmEditView: View {
    let alarm: AlarmItem
    @Binding var errorMessage: String?

    @Environment(\.dismiss) private var dismiss
    @State private var hour = 7
    @State private var minute = 0
    @State private var label = "起床"
    @State private var characterID = "pico"
    @State private var isEnabled = true
    @State private var weekdays: Set<Int> = [2, 3, 4, 5, 6]
    @State private var missions: Set<MissionType> = [.math, .memory]
    @State private var saving = false

    private let weekdaySymbols: [(Int, String)] = [
        (1, "日"), (2, "一"), (3, "二"), (4, "三"), (5, "四"), (6, "五"), (7, "六")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("时间") {
                    DatePicker(
                        "响铃时间",
                        selection: Binding(
                            get: { dateFrom(hour: hour, minute: minute) },
                            set: { newDate in
                                let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                hour = c.hour ?? 7
                                minute = c.minute ?? 0
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    TextField("标签", text: $label)
                }

                Section("重复") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(weekdaySymbols, id: \.0) { day, name in
                            Button {
                                if weekdays.contains(day) { weekdays.remove(day) } else { weekdays.insert(day) }
                            } label: {
                                Text(name)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(weekdays.contains(day) ? Color.indigo.opacity(0.18) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("周\(name)")
                        }
                    }
                    Text("全部不选 = 只响一次")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("叫醒角色") {
                    Picker("角色", selection: $characterID) {
                        Text("小鸡哔哔").tag("pico")
                        Text("仓鼠起司").tag("cheeze")
                        Text("面包君").tag("bready")
                    }
                }

                Section("晨间任务") {
                    ForEach(MissionType.allCases) { type in
                        Toggle(isOn: Binding(
                            get: { missions.contains(type) },
                            set: { on in
                                if on { missions.insert(type) } else { missions.remove(type) }
                            }
                        )) {
                            Label(type.title, systemImage: type.symbol)
                        }
                        .frame(minHeight: 44)
                    }
                    Text("至少选一项；任务按顺序执行。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Toggle("启用", isOn: $isEnabled)
                        .frame(minHeight: 44)
                }
            }
            .navigationTitle("编辑闹钟")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { Task { await save() } }
                        .disabled(saving || missions.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        hour = alarm.hour
        minute = alarm.minute
        label = alarm.label
        characterID = alarm.characterID
        isEnabled = alarm.isEnabled
        weekdays = Set(alarm.weekdays)
        missions = Set(alarm.missionTypes.compactMap { MissionType(rawValue: $0) })
    }

    private func save() async {
        saving = true
        alarm.hour = hour
        alarm.minute = minute
        alarm.label = label
        alarm.characterID = characterID
        alarm.isEnabled = isEnabled
        alarm.weekdays = weekdays.sorted()
        alarm.missionTypes = missions.map(\.rawValue).sorted()

        do {
            if isEnabled {
                try await AlarmScheduler.shared.schedule(item: alarm)
            } else {
                await AlarmScheduler.shared.cancel(item: alarm)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        saving = false
    }

    private func dateFrom(hour: Int, minute: Int) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = hour
        c.minute = minute
        return Calendar.current.date(from: c) ?? Date()
    }
}
