import SwiftUI

struct BubbleTapView: View {
    let onSuccess: () -> Void

    @State private var popped = Set<Int>()
    private let target = 6

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(spacing: 24) {
            Text("点泡泡")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            Text("戳破 \(target) 个泡泡（已戳破 \(popped.count)）")
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<9, id: \.self) { index in
                    Button {
                        if !popped.contains(index) {
                            popped.insert(index)
                            if popped.count == target { onSuccess() }
                        }
                    } label: {
                        Image(systemName: popped.contains(index) ? "circle" : "circle.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(popped.contains(index) ? .gray.opacity(0.3) : .indigo)
                            .frame(maxWidth: .infinity, minHeight: 72)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(popped.contains(index) ? "已戳破" : "未戳破的泡泡")
                }
            }
        }
        .padding(24)
    }
}

struct FindDifferentView: View {
    let onSuccess: () -> Void

    @State private var specialIndex = Int.random(in: 0..<16)
    @State private var message = "找出那个不一样的图标"

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(spacing: 24) {
            Text("找不同")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            Text(message)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<16, id: \.self) { index in
                    Button {
                        if index == specialIndex {
                            onSuccess()
                        } else {
                            message = "不是这个，再看看"
                        }
                    } label: {
                        Image(systemName: index == specialIndex ? "star.fill" : "circle.fill")
                            .font(.title2)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(index == specialIndex ? "星形" : "圆形")
                }
            }
        }
        .padding(24)
    }
}
