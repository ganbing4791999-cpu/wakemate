import SwiftUI

private struct Tile: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let label: String
}

struct MemoryMissionView: View {
    let onSuccess: () -> Void

    private let palette: [Tile] = [
        Tile(name: "circle.fill", color: .red, label: "红色圆形"),
        Tile(name: "square.fill", color: .blue, label: "蓝色方形"),
        Tile(name: "triangle.fill", color: .green, label: "绿色三角"),
        Tile(name: "diamond.fill", color: .orange, label: "橙色菱形")
    ]

    @State private var sequence: [Tile] = []
    @State private var showingSequence = true
    @State private var inputIndex = 0
    @State private var failed = false

    var body: some View {
        VStack(spacing: 24) {
            Text("记色块")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            Text(showingSequence ? "记住顺序" : (failed ? "顺序错了，重新开始" : "按刚才的顺序点"))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(sequence) { tile in
                    Image(systemName: tile.name)
                        .font(.title)
                        .foregroundStyle(showingSequence ? tile.color : .gray.opacity(0.25))
                        .frame(width: 56, height: 56)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel(showingSequence ? tile.label : "待选择")
                }
            }
            .frame(minHeight: 80)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(palette) { tile in
                    Button {
                        tap(tile)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tile.name)
                            Text(tile.label.replacingOccurrences(of: "色", with: ""))
                        }
                        .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .buttonStyle(.bordered)
                    .disabled(showingSequence)
                    .accessibilityLabel("选择\(tile.label)")
                }
            }
        }
        .padding(24)
        .onAppear(perform: start)
    }

    private func start() {
        sequence = (0..<3).compactMap { _ in palette.randomElement() }
        inputIndex = 0
        failed = false
        showingSequence = true
        Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            showingSequence = false
        }
    }

    private func tap(_ tile: Tile) {
        guard !showingSequence else { return }
        guard inputIndex < sequence.count else { return }

        if sequence[inputIndex].id == tile.id {
            inputIndex += 1
            if inputIndex == sequence.count {
                onSuccess()
            }
        } else {
            failed = true
            Task {
                try? await Task.sleep(nanoseconds: 700_000_000)
                start()
            }
        }
    }
}
