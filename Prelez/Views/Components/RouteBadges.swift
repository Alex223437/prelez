import SwiftUI

extension HoldColor {
    /// Color of the hold swatch in the UI.
    var swatch: Color {
        switch self {
        case .yellow: .yellow
        case .blue: .blue
        case .green: .green
        case .red: .red
        case .black: .black
        case .white: .white
        case .orange: .orange
        case .purple: .purple
        case .pink: .pink
        case .grey: .gray
        case .brown: .brown
        case .turquoise: .teal
        }
    }
}

/// Round swatch of the hold color. Content, so no glass.
struct HoldSwatch: View {
    let color: HoldColor
    var size: CGFloat = 22

    var body: some View {
        Circle()
            .fill(color.swatch.gradient)
            .overlay(Circle().strokeBorder(.primary.opacity(0.25), lineWidth: 1))
            .frame(width: size, height: size)
            .accessibilityLabel(color.czechName)
    }
}

/// One line of the routes list: swatch, grade, name, setter.
struct RouteRow: View {
    let route: Route

    var body: some View {
        HStack(spacing: 12) {
            HoldSwatch(color: route.color)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(route.grade.text)
                        .font(.headline.monospacedDigit())
                    Text(route.name ?? route.color.czechName)
                        .foregroundStyle(.secondary)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if route.attempts.contains(where: { $0.result == .send }) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("Přelezeno")
            }
        }
    }

    private var subtitle: String {
        var parts = [route.kind.czechName]
        if let number = route.number { parts.append("lajna \(number)") }
        if let setter = route.setter { parts.append(setter) }
        return parts.joined(separator: " · ")
    }
}
