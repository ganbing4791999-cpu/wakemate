import SwiftUI

struct MissionContainerView: View {
    let session: MissionSession
    let onAllComplete: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ProgressView(value: Double(session.completedCount), total: Double(session.types.count))
                    .padding(.horizontal)

                Text("任务 \(session.progressText)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("当前任务进度 \(session.progressText)")

                Spacer(minLength: 8)

                currentView

                Spacer()
            }
            .navigationTitle("醒伴 · 晨间任务")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var currentView: some View {
        switch session.currentType {
        case .math:
            MathMissionView(level: session.difficultyLevel) { session.advance() }
        case .memory:
            MemoryMissionView { session.advance() }
        case .photo:
            PhotoMissionView { session.advance() }
        case .bubble:
            BubbleTapView { session.advance() }
        case .findDifferent:
            FindDifferentView { session.advance() }
        }
        .onChange(of: session.isFinished) { _, finished in
            if finished { onAllComplete() }
        }
    }
}
