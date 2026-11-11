import SwiftUI

enum Theme {
    static let paper = Color(red: 0.965, green: 0.910, blue: 0.800)
    static let card = Color(red: 1.0, green: 0.985, blue: 0.945)
    static let ink = Color(red: 0.16, green: 0.11, blue: 0.07)
    static let red = Color(red: 0.86, green: 0.23, blue: 0.22)
    static let yellow = Color(red: 0.95, green: 0.74, blue: 0.18)
    static let blue = Color(red: 0.23, green: 0.46, blue: 0.82)
    static let green = Color(red: 0.20, green: 0.60, blue: 0.34)
    static let blush = Color(red: 0.96, green: 0.55, blue: 0.52)

    static func wash(_ color: PaintColor?) -> Color {
        switch color {
        case .red: return Color(red: 0.99, green: 0.90, blue: 0.86)
        case .yellow: return Color(red: 0.99, green: 0.95, blue: 0.82)
        case .blue: return Color(red: 0.88, green: 0.93, blue: 0.99)
        case .green: return Color(red: 0.88, green: 0.95, blue: 0.88)
        case .rainbow: return Color(red: 0.96, green: 0.91, blue: 0.98)
        case nil: return paper
        }
    }

    static func ink(on color: PaintColor) -> Color {
        color == .yellow ? ink : .white
    }
}

extension PaintColor {
    var color: Color {
        switch self {
        case .red: return Theme.red
        case .yellow: return Theme.yellow
        case .blue: return Theme.blue
        case .green: return Theme.green
        case .rainbow: return Theme.blush
        }
    }
}

struct CutShadow: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(0.26), radius: 0, x: 5, y: 5)
    }
}

struct KidButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.62), value: configuration.isPressed)
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.42
        var path = Path()
        for i in 0..<10 {
            let angle = (Double(i) * .pi / 5) - .pi / 2
            let radius = i.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

struct PaperBackground: View {
    var tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack {
                tint
                Image("PaperTexture")
                    .resizable(resizingMode: .tile)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .blendMode(.multiply)
                    .opacity(0.55)
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }
}
