import SwiftData
import SwiftUI

struct WishlistView: View {
    let store: CollectionStore

    @Query(sort: \CatalogFigure.sortIndex) private var figures: [CatalogFigure]
    @Query(sort: \WishlistItem.lastUpdatedAt, order: .reverse) private var wishlist: [WishlistItem]

    private let repository = CatalogRepository()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionTitle(
                    eyebrow: "Grail Radar",
                    title: "Wishlist & Price Tracker",
                    subtitle: "Keep wanted figures visible, with local target pricing and last-seen value notes."
                )

                if entries.isEmpty {
                    EmptyCollectorState(
                        title: "No grails yet",
                        message: "Star figures from detail screens to build your watchlist and track target prices.",
                        symbol: "star.circle.fill"
                    )
                } else {
                    ForEach(entries, id: \.0.id) { figure, item in
                        NavigationLink {
                            FigureDetailView(figure: figure, store: store)
                        } label: {
                            CollectorPanel {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(figure.name)
                                                .font(.system(.headline, design: .rounded, weight: .bold))
                                            Text(figure.subtitle)
                                                .font(.system(.subheadline, design: .rounded))
                                                .foregroundStyle(AppTheme.secondaryText)
                                        }
                                        Spacer()
                                        StatusChip(title: figure.era.rawValue, color: Color(hex: figure.accentHex))
                                    }

                                    HStack(spacing: 12) {
                                        MetricCard(label: "Target", value: (item.targetPrice ?? figure.msrp).currencyString, icon: "scope", accent: AppTheme.gold)
                                        MetricCard(label: "Last seen", value: (item.lastKnownPrice ?? 0).currencyString, icon: "tag.fill", accent: AppTheme.accent)
                                    }

                                    if item.notes.isEmpty == false {
                                        Text(item.notes)
                                            .font(.system(.footnote, design: .rounded))
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.background)
        .navigationTitle("Wishlist")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var entries: [(CatalogFigure, WishlistItem)] {
        wishlist.compactMap { item in
            guard let figure = repository.figure(withID: item.figureID, in: figures) else { return nil }
            return (figure, item)
        }
    }
}
