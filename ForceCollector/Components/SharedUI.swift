import SwiftUI

struct CollectorPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.panelFill())
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}

struct SectionTitle: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.gold)
                .tracking(1.1)

            Text(title)
                .font(AppTheme.displayFont(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.text)

            Text(subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }
}

struct MetricCard: View {
    let label: String
    let value: String
    let icon: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(accent)
                .padding(10)
                .background(accent.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(value)
                .font(AppTheme.displayFont(size: 26, weight: .bold))
                .foregroundStyle(AppTheme.text)

            Text(label)
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct StatusChip: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.system(.caption, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(color.opacity(0.2), in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 1))
    }
}

struct FigureHeroCard: View {
    let figure: CatalogFigure
    let owned: Bool
    let wishlisted: Bool

    var body: some View {
        CollectorPanel {
            VStack(alignment: .leading, spacing: 16) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: figure.accentHex).opacity(0.9), AppTheme.elevatedSurface],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 260)
                        .overlay(
                            VStack(alignment: .leading, spacing: 16) {
                                Spacer()
                                Image(systemName: figure.symbol)
                                    .font(.system(size: 60, weight: .black))
                                    .foregroundStyle(.white.opacity(0.92))
                                Text(figure.subtitle)
                                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            .padding(22)
                        )

                    VStack(alignment: .trailing, spacing: 8) {
                        if owned {
                            StatusChip(title: "OWNED", color: AppTheme.success)
                        }
                        if wishlisted {
                            StatusChip(title: "WANTED", color: AppTheme.gold)
                        }
                    }
                    .padding(16)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(figure.name)
                        .font(AppTheme.displayFont(size: 30, weight: .bold))

                    Text(figure.line)
                        .font(.system(.headline, design: .rounded, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)

                    HStack(spacing: 8) {
                        StatusChip(title: figure.era.rawValue, color: AppTheme.accent)
                        StatusChip(title: figure.faction.rawValue, color: Color(hex: figure.accentHex))
                    }
                }
            }
        }
    }
}

struct EmptyCollectorState: View {
    let title: String
    let message: String
    let symbol: String

    var body: some View {
        CollectorPanel {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(AppTheme.gold)

                Text(title)
                    .font(AppTheme.displayFont(size: 24, weight: .bold))

                Text(message)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}

struct PriceField: View {
    let title: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)

            TextField("$0.00", text: $value)
                .keyboardType(.decimalPad)
                .padding(14)
                .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
