import SwiftUI

private struct MathQuestion {
    let text: String
    let answer: Int
}

struct MathMissionView: View {
    let level: Int
    let onSuccess: () -> Void

    @State private var question = MathQuestion(text: "7 × 8 = ?", answer: 56)
    @State private var input = ""
    @State private var feedback = "输入答案后点确认"

    var body: some View {
        VStack(spacing: 24) {
            Text("算一道")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            Text(question.text)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .accessibilityLabel("数学题：\(question.text)")

            TextField("答案", text: $input)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .font(.title)
                .multilineTextAlignment(.center)
                .accessibilityLabel("答案输入框")
                .frame(maxWidth: 220)

            Text(feedback)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityLabel(feedback)

            Button(action: submit) {
                Text("确认").font(.headline).frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: 300)
            .accessibilityLabel("确认答案")
        }
        .padding(24)
        .onAppear { question = makeQuestion(level: level) }
    }

    private func submit() {
        guard Int(input) == question.answer else {
            input = ""
            feedback = "不对，再算一次"
            return
        }
        onSuccess()
    }

    private func makeQuestion(level: Int) -> MathQuestion {
        let a = Int.random(in: 3...9)
        let b = Int.random(in: 3...9)
        if level >= 4 {
            let c = Int.random(in: 2...6)
            return MathQuestion(text: "\(a) × \(b) + \(c) = ?", answer: a * b + c)
        }
        if level >= 2 {
            return MathQuestion(text: "\(a) × \(b) = ?", answer: a * b)
        }
        return MathQuestion(text: "\(a + 5) + \(b + 3) = ?", answer: a + b + 8)
    }
}
