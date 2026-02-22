import SwiftUI

enum GameDayPalette {
    static let accent = Color(red: 0.07, green: 0.42, blue: 0.95)

    static func backgroundTop(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color(red: 0.02, green: 0.03, blue: 0.05)
        default:
            return Color(red: 0.95, green: 0.97, blue: 0.99)
        }
    }

    static func backgroundBottom(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color(red: 0.06, green: 0.08, blue: 0.12)
        default:
            return Color(red: 0.90, green: 0.93, blue: 0.97)
        }
    }

    static func ambientGlow(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color.white.opacity(0.08)
        default:
            return Color.white.opacity(0.45)
        }
    }

    static func topOverlay(for scheme: ColorScheme) -> LinearGradient {
        switch scheme {
        case .dark:
            return LinearGradient(
                colors: [Color.white.opacity(0.10), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(
                colors: [Color.white.opacity(0.28), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    static func glassStroke(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color.white.opacity(0.16)
        default:
            return Color.black.opacity(0.08)
        }
    }

    static func glassShadow(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color.black.opacity(0.35)
        default:
            return Color.black.opacity(0.06)
        }
    }

    static func readinessTrack(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color.white.opacity(0.14)
        default:
            return Color.black.opacity(0.08)
        }
    }

    static func readinessGradient(score: Int) -> LinearGradient {
        switch score {
        case 85...:
            return LinearGradient(colors: [Color.green.opacity(0.8), Color.mint.opacity(0.65)], startPoint: .leading, endPoint: .trailing)
        case 70..<85:
            return LinearGradient(colors: [Color.blue.opacity(0.85), Color.cyan.opacity(0.65)], startPoint: .leading, endPoint: .trailing)
        case 50..<70:
            return LinearGradient(colors: [Color.orange.opacity(0.85), Color.yellow.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        default:
            return LinearGradient(colors: [Color.red.opacity(0.8), Color.orange.opacity(0.75)], startPoint: .leading, endPoint: .trailing)
        }
    }
}

struct GameDayBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    GameDayPalette.backgroundTop(for: colorScheme),
                    GameDayPalette.backgroundBottom(for: colorScheme)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(GameDayPalette.ambientGlow(for: colorScheme))
                .blur(radius: 70)
                .frame(width: 260)
                .offset(x: 140, y: -280)

            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(GameDayPalette.topOverlay(for: colorScheme))
                .padding(.horizontal, 24)
                .padding(.top, 10)
        }
        .ignoresSafeArea()
    }
}

struct GameDaySectionTitle: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct GameDayStatusPill: View {
    let text: String
    let systemImage: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(GameDayPalette.glassStroke(for: colorScheme), lineWidth: 0.5)
            )
    }
}

private struct GameDayGlassCardModifier: ViewModifier {
    let padding: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(GameDayPalette.glassStroke(for: colorScheme), lineWidth: 0.5)
            )
            .shadow(
                color: GameDayPalette.glassShadow(for: colorScheme),
                radius: colorScheme == .dark ? 14 : 8,
                x: 0,
                y: colorScheme == .dark ? 6 : 2
            )
            .glassEffect()
    }
}

extension View {
    func gameDayGlassCard(_ padding: CGFloat = 18) -> some View {
        modifier(GameDayGlassCardModifier(padding: padding))
    }

    func gameDayMetricNumber() -> some View {
        self
            .font(.system(size: 40, weight: .semibold, design: .rounded))
            .contentTransition(.numericText())
            .monospacedDigit()
    }
}
