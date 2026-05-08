import SwiftData
import SwiftUI

struct DashboardView: View {
    let store: CollectionStore
    @Binding var selectedTab: AppTab

    @Query(sort: \CatalogFigure.sortIndex) private var figures: [CatalogFigure]
    @Query(sort: \CollectionItem.acquiredAt, order: .reverse) private var collection: [CollectionItem]
    @Query(sort: \WishlistItem.lastUpdatedAt, order: .reverse) private var wishlist: [WishlistItem]

    private let repository = CatalogRepository()
    private let analytics = AnalyticsService()

    var body: some View {
        let snapshot = analytics.snapshot(figures: figures, collection: collection, wishlist: wishlist)

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionTitle(
                    eyebrow: "Black Series HQ",
                    title: "Collector Dashboard",
                    subtitle: "Your local-first command center for the hunt, the shelf, and the wishlist."
                )

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Quick jump")
                            .font(.system(.headline, design: .rounded, weight: .semibold))

                        HStack(spacing: 12) {
                            dashboardButton("Scan a box", systemImage: "barcode.viewfinder", color: AppTheme.gold) {
                                selectedTab = .scan
                            }
                            dashboardButton("Open collection", systemImage: "shippingbox.fill", color: AppTheme.accent) {
                                selectedTab = .collection
                            }
                            NavigationLink {
                                AnalyticsView(snapshot: snapshot)
                            } label: {
                                dashboardCard("Stats", systemImage: "chart.xyaxis.line", color: AppTheme.success)
                            }
                        }
                    }
                }

                HStack(spacing: 14) {
                    MetricCard(label: "Owned figures", value: "\(snapshot.ownedCount)", icon: "tray.full.fill", accent: AppTheme.accent)
                    MetricCard(label: "Wishlist", value: "\(snapshot.wishlistCount)", icon: "star.fill", accent: AppTheme.gold)
                }

                HStack(spacing: 14) {
                    MetricCard(label: "Completion", value: snapshot.completionRatio.percentString, icon: "gauge.high", accent: AppTheme.success)
                    MetricCard(label: "Favorites", value: "\(snapshot.favoriteCount)", icon: "heart.fill", accent: AppTheme.danger)
                }

                if let recent = recentFigures.prefix(3).first {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent addition")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                        NavigationLink {
                            FigureDetailView(figure: recent, store: store)
                        } label: {
                            FigureHeroCard(
                                figure: recent,
                                owned: true,
                                wishlisted: store.isWishlisted(recent.id, items: wishlist)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Era progress")
                            .font(.system(.headline, design: .rounded, weight: .semibold))

                        ForEach(snapshot.byEra, id: \.0) { era, count in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(era.rawValue)
                                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    Spacer()
                                    Text("\(count)")
                                        .foregroundStyle(AppTheme.gold)
                                }

                                GeometryReader { proxy in
                                    let progress = snapshot.ownedCount == 0 ? 0 : CGFloat(count) / CGFloat(max(snapshot.ownedCount, 1))
                                    RoundedRectangle(cornerRadius: 999)
                                        .fill(AppTheme.elevatedSurface)
                                        .overlay(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 999)
                                                .fill(Color(hex: colorHex(for: era)))
                                                .frame(width: proxy.size.width * progress)
                                        }
                                }
                                .frame(height: 10)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var recentFigures: [CatalogFigure] {
        let recentIDs = collection.map(\.figureID)
        return repository.figures(for: recentIDs, in: figures)
    }

    @ViewBuilder
    private func dashboardButton(_ title: String, systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            dashboardCard(title, systemImage: systemImage, color: color)
        }
        .buttonStyle(.plain)
    }

    private func dashboardCard(_ title: String, systemImage: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .black))
                .padding(10)
                .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .multilineTextAlignment(.leading)
                .foregroundStyle(AppTheme.text)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .padding(14)
        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func colorHex(for era: FigureEra) -> String {
        switch era {
        case .prequel: return "#4AC0E0"
        case .cloneWars: return "#3F7BFF"
        case .original: return "#F6C453"
        case .sequel: return "#FF7D85"
        case .mando: return "#66D7A4"
        case .gamingGreats: return "#A56EFF"
        }
    }
}

struct AnalyticsView: View {
    let snapshot: AnalyticsSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionTitle(
                    eyebrow: "Collection Intel",
                    title: "Analytics & Stats",
                    subtitle: "Local insights from your owned shelves and wanted grails."
                )

                HStack(spacing: 14) {
                    MetricCard(label: "Average buy", value: snapshot.averageOwnedPrice.currencyString, icon: "creditcard.fill", accent: AppTheme.gold)
                    MetricCard(label: "Wishlist value", value: snapshot.recentWishlistValue.currencyString, icon: "tag.fill", accent: AppTheme.accent)
                }

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Status mix")
                            .font(.system(.headline, design: .rounded, weight: .semibold))

                        ForEach(snapshot.byStatus, id: \.0) { status, count in
                            HStack {
                                StatusChip(title: status.rawValue, color: status.color)
                                Spacer()
                                Text("\(count)")
                                    .font(AppTheme.displayFont(size: 20, weight: .bold))
                            }
                        }
                    }
                }

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Coverage")
                            .font(.system(.headline, design: .rounded, weight: .semibold))

                        Text("\(snapshot.ownedCount) of \(snapshot.totalCatalog) seeded figures tracked.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)

                        GeometryReader { proxy in
                            RoundedRectangle(cornerRadius: 999)
                                .fill(AppTheme.elevatedSurface)
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 999)
                                        .fill(
                                            LinearGradient(
                                                colors: [AppTheme.accent, AppTheme.gold],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: proxy.size.width * snapshot.completionRatio)
                                }
                        }
                        .frame(height: 14)
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.background)
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension CollectionStatus {
    var color: Color {
        switch self {
        case .sealed: return AppTheme.accent
        case .opened: return AppTheme.warning
        case .displayed: return AppTheme.success
        case .archived: return AppTheme.secondaryText
        }
    }
}

extension Double {
    var percentString: String {
        "\(Int((self * 100).rounded()))%"
    }

    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$0"
    }
}
