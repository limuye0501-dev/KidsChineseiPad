import SwiftUI

/// Hold-to-confirm arithmetic. Kids can open this by accident; they cannot hold the
/// right number long enough by tapping around. No links live behind it.
struct ParentGateView: View {
    var onSuccess: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var left = Int.random(in: 3...8)
    @State private var right = Int.random(in: 2...7)
    @State private var options: [Int] = []

    var body: some View {
        ZStack {
            PaperBackground(tint: Theme.paper).ignoresSafeArea()
            VStack(spacing: 22) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(Theme.card).overlay(Circle().stroke(Theme.ink, lineWidth: 3)))
                    }
                    .accessibilityLabel("Close")
                    Spacer()
                }
                Text("Grown-ups")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("Press and hold the answer")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.7))
                Text("\(left) + \(right)")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .padding(.vertical, 6)
                HStack(spacing: 28) {
                    ForEach(options, id: \.self) { value in
                        HoldChoice(value: value, correct: value == left + right) {
                            onSuccess()
                        }
                    }
                }
                Spacer()
            }
            .padding(28)
        }
        .onAppear { options = makeOptions() }
    }

    private func makeOptions() -> [Int] {
        let sum = left + right
        var values = [sum]
        var extra = sum + 3
        while values.count < 3 {
            if extra != sum, extra > 0, !values.contains(extra) { values.append(extra) }
            extra -= 1
            if extra < sum - 6 { extra = sum + 5 }
        }
        return values.shuffled()
    }
}

private struct HoldChoice: View {
    let value: Int
    let correct: Bool
    let onSuccess: () -> Void
    @State private var hold: CGFloat = 0
    @State private var shake = 0
    @State private var passed = false

    var body: some View {
        ZStack {
            Circle().fill(Theme.card)
            Circle().stroke(Theme.ink, lineWidth: 4)
            Circle()
                .trim(from: 0, to: hold)
                .stroke(Theme.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(8)
            Text("\(value)")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
        }
        .frame(width: 120, height: 120)
        .offset(x: CGFloat(shake % 2 == 0 ? 0 : 8))
        .modifier(CutShadow())
        .accessibilityLabel("\(value)")
        .onLongPressGesture(minimumDuration: 1.25, maximumDistance: 40, pressing: { pressing in
            if pressing {
                withAnimation(.linear(duration: 1.25)) { hold = 1 }
            } else if !passed {
                withAnimation(.easeOut(duration: 0.15)) { hold = 0 }
            }
        }, perform: {
            if correct {
                passed = true
                onSuccess()
            } else {
                hold = 0
                shake += 1
            }
        })
    }
}
