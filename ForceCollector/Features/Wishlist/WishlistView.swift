import SwiftData
import SwiftUI

struct WishlistView: View {
    let store: CollectionStore

    @Query(sort: \CatalogFigure.sortIndex) private var figures: [CatalogFigure]
    @Query(sort: \WishlistItem.lastUpdatedAt, order: .reverse) private var wishlist: [WishlistItem]

    private let repository = CatalogRepository()

    var body: some View {
        StitchScreen(title: "Wishlist", trailingIcon: "magnifyingglass") {
            VStack(alignment: .leading, spacing: 14) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        wishlistFilter("Sort: Price Low", icon: "arrow.up.arrow.down")
                        wishlistFilter("Filter: Exclusives", icon: "line.3.horizontal.decrease")
                        wishlistFilter("Status: In Stock", icon: "checkmark.circle")
                    }
                    .padding(.horizontal, 16)
                }

                if entries.isEmpty {
                    EmptyCollectorState(
                        title: "No grails yet",
                        message: "Star figures from detail screens to build your watchlist and track target prices.",
                        symbol: "star.circle.fill"
                    )
                    .padding(16)
                } else {
                    ForEach(entries, id: \.0.id) { figure, item in
                        NavigationLink {
                            FigureDetailView(figure: figure, store: store)
                        } label: {
                            WishlistRow(figure: figure, item: item)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.top, 10)
        }
    }

    private var entries: [(CatalogFigure, WishlistItem)] {
        wishlist.compactMap { item in
            guard let figure = repository.figure(withID: item.figureID, in: figures) else { return nil }
            return (figure, item)
        }
    }

    private func wishlistFilter(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
        }
        .font(AppTheme.labelFont(size: 12, weight: .semibold))
        .foregroundStyle(AppTheme.secondaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.elevatedSurface, in: Capsule())
        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
    }
}

private struct WishlistRow: View {
    let figure: CatalogFigure
    let item: WishlistItem

    var body: some View {
        HStack(spacing: 14) {
            StitchFigureArtwork(figure: figure, contentMode: .fill)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(figure.name)
                            .font(AppTheme.labelFont(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(1)

                        Text("\(figure.line) • \(figure.wave)")
                            .font(AppTheme.labelFont(size: 12))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: item.lastKnownPrice == nil ? "bell" : "bell.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(item.lastKnownPrice == nil ? AppTheme.secondaryText : AppTheme.electric)
                }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(displayedPrice.currencyString)
                                .font(AppTheme.displayFont(size: 18, weight: .bold))
                                .foregroundStyle(AppTheme.text)

                            if let trend {
                                TrendBadge(direction: trend.direction, percent: trend.percent)
                            }
                        }

                        Text(priceLabel)
                            .font(AppTheme.labelFont(size: 10))
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()

                    Text("Buy")
                        .font(AppTheme.labelFont(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .textCase(.uppercase)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(12)
        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
    }

    private var targetPrice: Double {
        item.targetPrice ?? figure.msrp
    }

    private var displayedPrice: Double {
        item.lastKnownPrice ?? targetPrice
    }

    private var priceLabel: String {
        if item.lastKnownPrice != nil {
            return "Avg. Market Price"
        }
        return item.targetPrice == nil ? "MSRP Target" : "Target Price"
    }

    private var trend: (direction: TrendBadge.Direction, percent: Double)? {
        guard let lastKnownPrice = item.lastKnownPrice, targetPrice > 0 else { return nil }
        let delta = lastKnownPrice - targetPrice
        let percent = abs(delta / targetPrice) * 100
        if abs(delta) < 0.01 {
            return (.stable, 0)
        }
        return (delta > 0 ? .up : .down, percent)
    }
}

private struct TrendBadge: View {
    enum Direction {
        case up, down, stable
    }

    let direction: Direction
    let percent: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: direction.symbolName)
                .font(.system(size: 9, weight: .bold))
            Text("\(Int(percent.rounded()))%")
                .font(AppTheme.labelFont(size: 10, weight: .bold))
        }
        .foregroundStyle(direction.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(direction.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

private extension TrendBadge.Direction {
    var symbolName: String {
        switch self {
        case .up: "arrow.up.right"
        case .down: "arrow.down.right"
        case .stable: "minus"
        }
    }

    var color: Color {
        switch self {
        case .up: AppTheme.warning
        case .down: AppTheme.electric
        case .stable: AppTheme.secondaryText
        }
    }
}
