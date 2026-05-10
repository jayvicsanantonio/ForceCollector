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

        StitchScreen(title: "Collector", subtitle: "Welcome back", trailingIcon: "gearshape.fill") {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 12) {
                    MetricCard(label: "Total Figs", value: "\(max(snapshot.totalCatalog, snapshot.ownedCount))", icon: "archivebox", accent: AppTheme.text)
                    MetricCard(label: "Value", value: collectionValue, icon: "dollarsign", accent: AppTheme.accent)
                    MetricCard(label: "Complete", value: snapshot.completionRatio.percentString, icon: "gauge", accent: AppTheme.text)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Drops")
                            .font(AppTheme.displayFont(size: 18, weight: .bold))
                        Spacer()
                        Button("View All") {
                            selectedTab = .collection
                        }
                        .font(AppTheme.labelFont(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.electric)
                        .textCase(.uppercase)
                    }
                    .padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(recentFigures, id: \.id) { figure in
                                NavigationLink {
                                    FigureDetailView(figure: figure, store: store)
                                } label: {
                                    RecentDropCard(
                                        figure: figure,
                                        isNew: isRecentlyAcquired(figure)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                    }
                }

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Hunt Progress")
                                .font(AppTheme.displayFont(size: 18, weight: .bold))
                                .textCase(.uppercase)
                            Spacer()
                            Image(systemName: "bookmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AppTheme.electric)
                                .frame(width: 32, height: 32)
                                .background(AppTheme.surface, in: Circle())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .bottom) {
                                Text("Phase 4 Collection")
                                    .font(AppTheme.labelFont(size: 14, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.86))
                                Spacer()
                                Text(snapshot.completionRatio.percentString)
                                    .font(AppTheme.labelFont(size: 12, weight: .bold))
                                    .foregroundStyle(AppTheme.electric)
                            }

                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 999)
                                        .fill(AppTheme.background)
                                    if snapshot.completionRatio > 0 {
                                        RoundedRectangle(cornerRadius: 999)
                                            .fill(AppTheme.electric)
                                            .frame(width: max(8, proxy.size.width * snapshot.completionRatio))
                                            .shadow(color: AppTheme.electric.opacity(0.55), radius: 12)
                                    }
                                }
                            }
                            .frame(height: 10)

                            Text("\(max(snapshot.totalCatalog - snapshot.ownedCount, 0)) figures remaining to complete this wave.")
                                .font(AppTheme.labelFont(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.navIcon.opacity(0.6))
                        }

                        Button {
                            selectedTab = .wishlist
                        } label: {
                            HStack {
                                Spacer()
                                Text("View Wishlist")
                                    .font(AppTheme.labelFont(size: 14, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(AppTheme.electric)
                                Spacer()
                            }
                            .padding(.vertical, 13)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                NavigationLink {
                    AnalyticsView(snapshot: snapshot)
                } label: {
                    AnalyticsPromo()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
            }
        }
    }

    private var recentFigures: [CatalogFigure] {
        let recentIDs = collection.map(\.figureID)
        let recentIDSet = Set(recentIDs)
        let owned = repository.figures(for: recentIDs, in: figures)
        if owned.isEmpty {
            return Array(figures.sorted { left, right in
                if StitchAsset.hasFigureImage(for: left) != StitchAsset.hasFigureImage(for: right) {
                    return StitchAsset.hasFigureImage(for: left)
                }
                return left.sortIndex < right.sortIndex
            }.prefix(6))
        }
        var result = Array(owned.prefix(6))
        if result.count < 6 {
            result.append(contentsOf: figures.lazy.filter { recentIDSet.contains($0.id) == false }.prefix(6 - result.count))
        }
        return result
    }

    private func isRecentlyAcquired(_ figure: CatalogFigure) -> Bool {
        guard let item = collection.first(where: { $0.figureID == figure.id }),
              let threshold = Calendar.current.date(byAdding: .day, value: -14, to: .now)
        else {
            return false
        }

        return item.acquiredAt >= threshold
    }

    private var collectionValue: String {
        let value = collection.compactMap(\.purchasePrice).reduce(0, +)
        return value >= 1000 ? "$\(String(format: "%.1fk", value / 1000))" : value.currencyString
    }
}

struct AnalyticsView: View {
    let snapshot: AnalyticsSnapshot

    var body: some View {
        StitchScreen(title: "Analytics", trailingIcon: "chart.xyaxis.line", showsBackButton: true) {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(
                    eyebrow: "Collection Intel",
                    title: "Analytics & Stats",
                    subtitle: "Local insights from your shelves, watchlist, status mix, and collection coverage."
                )

                HStack(spacing: 12) {
                    MetricCard(label: "Average buy", value: snapshot.averageOwnedPrice.currencyString, icon: "creditcard.fill", accent: AppTheme.electric)
                    MetricCard(label: "Wishlist value", value: snapshot.recentWishlistValue.currencyString, icon: "tag.fill", accent: AppTheme.accent)
                }

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Status Mix")
                            .font(AppTheme.displayFont(size: 18, weight: .bold))

                        ForEach(snapshot.byStatus, id: \.0) { status, count in
                            HStack {
                                StatusChip(title: status.rawValue, color: status.color)
                                Spacer()
                                Text("\(count)")
                                    .font(AppTheme.displayFont(size: 22, weight: .bold))
                            }
                        }
                    }
                }

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Coverage")
                            .font(AppTheme.displayFont(size: 18, weight: .bold))

                        Text("\(snapshot.ownedCount) of \(snapshot.totalCatalog) seeded figures tracked.")
                            .font(AppTheme.labelFont(size: 15))
                            .foregroundStyle(AppTheme.secondaryText)

                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 999).fill(AppTheme.background)
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(LinearGradient(colors: [AppTheme.accent, AppTheme.electric], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: proxy.size.width * snapshot.completionRatio)
                            }
                        }
                        .frame(height: 14)
                    }
                }
            }
            .padding(16)
        }
    }
}

private struct RecentDropCard: View {
    let figure: CatalogFigure
    let isNew: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                StitchFigureArtwork(figure: figure, contentMode: .fill)
                    .frame(width: 128, height: 214)
                    .clipped()
                    .overlay(
                        LinearGradient(colors: [.clear, .black.opacity(0.82)], startPoint: .center, endPoint: .bottom)
                    )

                if isNew {
                    StatusChip(title: "New", color: AppTheme.electric)
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))

            Text(figure.name)
                .font(AppTheme.labelFont(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)

            Text(figure.subtitle)
                .font(AppTheme.labelFont(size: 11))
                .foregroundStyle(AppTheme.navIcon.opacity(0.5))
                .lineLimit(1)
        }
        .frame(width: 128, alignment: .leading)
    }
}

private struct AnalyticsPromo: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            StitchRemoteImage(urlString: StitchAsset.splash, contentMode: .fill)
                .frame(height: 170)
                .clipped()

            LinearGradient(colors: [.clear, AppTheme.background.opacity(0.94)], startPoint: .top, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 8) {
                Text("Pre-Order")
                    .font(AppTheme.labelFont(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.background)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.electric, in: RoundedRectangle(cornerRadius: 4, style: .continuous))

                Text("Collection Analytics & Stats")
                    .font(AppTheme.displayFont(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.text)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))
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
