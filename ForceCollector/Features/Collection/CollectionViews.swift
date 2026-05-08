import SwiftData
import SwiftUI

struct CollectionGridView: View {
    let store: CollectionStore

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CatalogFigure.sortIndex) private var figures: [CatalogFigure]
    @Query(sort: \CollectionItem.acquiredAt, order: .reverse) private var collection: [CollectionItem]
    @Query(sort: \WishlistItem.lastUpdatedAt, order: .reverse) private var wishlist: [WishlistItem]

    @State private var searchText = ""
    @State private var selectedEra: FigureEra?
    @State private var selectedScope: CollectionScope = .owned

    private let repository = CatalogRepository()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionTitle(
                    eyebrow: "My Vault",
                    title: "Collection Grid",
                    subtitle: "Filter your shelf, find missing eras, and jump into figure detail fast."
                )

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        TextField("Search figure, wave, or line", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .padding(14)
                            .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                        Picker("Scope", selection: $selectedScope) {
                            ForEach(CollectionScope.allCases) { scope in
                                Text(scope.rawValue).tag(scope)
                            }
                        }
                        .pickerStyle(.segmented)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                filterChip(title: "All Eras", active: selectedEra == nil) {
                                    selectedEra = nil
                                }

                                ForEach(FigureEra.allCases) { era in
                                    filterChip(title: era.rawValue, active: selectedEra == era) {
                                        selectedEra = era
                                    }
                                }
                            }
                        }
                    }
                }

                if filteredFigures.isEmpty {
                    EmptyCollectorState(
                        title: "No figures found",
                        message: "Try a different filter, or switch from owned-only to the full starter catalog.",
                        symbol: "shippingbox.and.arrow.backward.fill"
                    )
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(filteredFigures, id: \.id) { figure in
                            NavigationLink {
                                FigureDetailView(figure: figure, store: store)
                            } label: {
                                figureTile(for: figure)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.background)
        .navigationTitle("Collection")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filteredFigures: [CatalogFigure] {
        let ownedIDs = store.ownedIDs(in: collection)
        return repository.search(searchText, in: figures)
            .filter { figure in
                (selectedEra == nil || figure.era == selectedEra) &&
                (selectedScope == .allCatalog || ownedIDs.contains(figure.id))
            }
    }

    @ViewBuilder
    private func filterChip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(active ? .white : AppTheme.secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(active ? AppTheme.accent : AppTheme.elevatedSurface, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func figureTile(for figure: CatalogFigure) -> some View {
        let owned = store.isOwned(figure.id, items: collection)
        let wishlisted = store.isWishlisted(figure.id, items: wishlist)

        return VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: figure.accentHex), AppTheme.elevatedSurface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 148)
                .overlay(
                    VStack(alignment: .leading) {
                        HStack {
                            if owned {
                                StatusChip(title: "OWNED", color: AppTheme.success)
                            }
                            Spacer()
                            if wishlisted {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(AppTheme.gold)
                            }
                        }
                        Spacer()
                        Image(systemName: figure.symbol)
                            .font(.system(size: 34, weight: .black))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(14)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(figure.name)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.text)

                Text(figure.subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(AppTheme.panelFill(), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

struct FigureDetailView: View {
    let figure: CatalogFigure
    let store: CollectionStore

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CollectionItem.acquiredAt, order: .reverse) private var collection: [CollectionItem]
    @Query(sort: \WishlistItem.lastUpdatedAt, order: .reverse) private var wishlist: [WishlistItem]

    @State private var collectionNotes = ""
    @State private var collectionSource = ""
    @State private var purchasePrice = ""
    @State private var targetPrice = ""
    @State private var lastKnownPrice = ""
    @State private var wishlistNotes = ""
    @State private var selectedStatus: CollectionStatus = .sealed
    @State private var favorite = false

    var body: some View {
        let ownedItem = store.item(for: figure.id, in: collection)
        let wishItem = store.wishlistItem(for: figure.id, in: wishlist)

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FigureHeroCard(
                    figure: figure,
                    owned: ownedItem != nil,
                    wishlisted: wishItem != nil
                )

                HStack(spacing: 12) {
                    actionButton(
                        title: ownedItem == nil ? "Add to Collection" : "Remove from Collection",
                        icon: ownedItem == nil ? "plus.circle.fill" : "tray.and.arrow.down.fill",
                        color: ownedItem == nil ? AppTheme.success : AppTheme.danger
                    ) {
                        try? store.toggleOwned(figure: figure, in: collection, context: modelContext)
                        syncFormState()
                    }

                    actionButton(
                        title: wishItem == nil ? "Watch Price" : "Remove Watch",
                        icon: "star.fill",
                        color: AppTheme.gold
                    ) {
                        try? store.toggleWishlist(figure: figure, in: wishlist, context: modelContext)
                        syncFormState()
                    }
                }

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Lore & release")
                            .font(.system(.headline, design: .rounded, weight: .semibold))

                        Text(figure.lore)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)

                        Divider().overlay(AppTheme.border)

                        detailRow("Wave", figure.wave)
                        detailRow("Faction", figure.faction.rawValue)
                        detailRow("Era", figure.era.rawValue)
                        detailRow("MSRP", figure.msrp.currencyString)
                        detailRow("Release year", "\(figure.releaseYear)")
                        detailRow("Barcode", figure.barcode ?? "Not seeded")
                    }
                }

                if ownedItem != nil {
                    CollectorPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Owned status")
                                .font(.system(.headline, design: .rounded, weight: .semibold))

                            Picker("Condition", selection: $selectedStatus) {
                                ForEach(CollectionStatus.allCases) { status in
                                    Text(status.rawValue).tag(status)
                                }
                            }
                            .pickerStyle(.segmented)

                            TextField("Acquired from", text: $collectionSource)
                                .padding(14)
                                .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                            PriceField(title: "Purchase price", value: $purchasePrice)

                            Toggle("Favorite display piece", isOn: $favorite)
                                .toggleStyle(.switch)

                            TextField("Collection notes", text: $collectionNotes, axis: .vertical)
                                .lineLimit(4, reservesSpace: true)
                                .padding(14)
                                .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                            Button("Save owned details") {
                                try? store.updateCollectionItem(
                                    figureID: figure.id,
                                    items: collection,
                                    context: modelContext,
                                    status: selectedStatus,
                                    source: collectionSource,
                                    notes: collectionNotes,
                                    purchasePrice: Double(purchasePrice),
                                    isFavorite: favorite
                                )
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.accent)
                        }
                    }
                }

                if wishItem != nil {
                    CollectorPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Wishlist tracking")
                                .font(.system(.headline, design: .rounded, weight: .semibold))

                            HStack(spacing: 12) {
                                PriceField(title: "Target price", value: $targetPrice)
                                PriceField(title: "Last seen", value: $lastKnownPrice)
                            }

                            TextField("Wishlist notes", text: $wishlistNotes, axis: .vertical)
                                .lineLimit(3, reservesSpace: true)
                                .padding(14)
                                .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                            Button("Save watch details") {
                                try? store.updateWishlist(
                                    figureID: figure.id,
                                    items: wishlist,
                                    context: modelContext,
                                    targetPrice: Double(targetPrice),
                                    lastKnownPrice: Double(lastKnownPrice),
                                    notes: wishlistNotes
                                )
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.gold)
                            .foregroundStyle(.black)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.background)
        .navigationTitle(figure.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: collection.count + wishlist.count) {
            syncFormState()
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.system(.subheadline, design: .rounded))
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
    }

    private func syncFormState() {
        if let owned = store.item(for: figure.id, in: collection) {
            selectedStatus = owned.status
            collectionSource = owned.source
            collectionNotes = owned.notes
            purchasePrice = owned.purchasePrice?.cleanNumber ?? ""
            favorite = owned.isFavorite
        } else {
            selectedStatus = .sealed
            collectionSource = ""
            collectionNotes = ""
            purchasePrice = ""
            favorite = false
        }

        if let wished = store.wishlistItem(for: figure.id, in: wishlist) {
            targetPrice = wished.targetPrice?.cleanNumber ?? ""
            lastKnownPrice = wished.lastKnownPrice?.cleanNumber ?? ""
            wishlistNotes = wished.notes
        } else {
            targetPrice = ""
            lastKnownPrice = ""
            wishlistNotes = ""
        }
    }
}

private extension Double {
    var cleanNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
