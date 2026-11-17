import SwiftUI

private struct CharacterInfo: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let color: Color
    let desc: String
}

struct CharacterView: View {
    private let characters: [CharacterInfo] = [
        CharacterInfo(id: "pico", name: "小鸡哔哔", symbol: "bird.fill", color: .yellow, desc: "嗓门最大的早起搭档，负责把闹铃叫得响亮。"),
        CharacterInfo(id: "cheeze", name: "仓鼠起司", symbol: "hare.fill", color: .orange, desc: "喜欢把任务拆成小块，适合刚开始早起的人。"),
        CharacterInfo(id: "bready", name: "面包君", symbol: "birthday.cake.fill", color: .brown, desc: "安静但有耐心，适合合租和宿舍场景。")
    ]

    private var todayIndex: Int {
        Calendar.current.component(.day, from: Date()) % characters.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section("今日值班") {
                    let today = characters[todayIndex]
                    HStack(spacing: 16) {
                        Image(systemName: today.symbol)
                            .font(.system(size: 44))
                            .foregroundStyle(today.color)
                            .frame(width: 60, height: 60)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading) {
                            Text(today.name).font(.headline)
                            Text(today.desc).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .frame(minHeight: 80)
                }

                Section("角色图鉴") {
                    ForEach(characters) { character in
                        HStack(spacing: 14) {
                            Image(systemName: character.symbol)
                                .font(.title)
                                .foregroundStyle(character.color)
                                .frame(width: 44, height: 44)
                            VStack(alignment: .leading) {
                                Text(character.name).font(.headline)
                                Text(character.desc).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .frame(minHeight: 64)
                        .accessibilityLabel("\(character.name)：\(character.desc)")
                    }
                }
            }
            .navigationTitle("角色")
        }
    }
}
