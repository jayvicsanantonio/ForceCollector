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
        StitchScreen(title: "My Collection", trailingIcon: "line.3.horizontal.decrease") {
            VStack(spacing: 14) {
                searchBar
                    .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        filterChip(title: "All", active: selectedEra == nil) {
                            selectedEra = nil
                        }

                        ForEach(FigureEra.allCases) { era in
                            filterChip(title: shortEra(era), active: selectedEra == era) {
                                selectedEra = era
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Picker("Scope", selection: $selectedScope) {
                    ForEach(CollectionScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                if filteredFigures.isEmpty {
                    EmptyCollectorState(
                        title: "No figures found",
                        message: "Try another faction, era, or search phrase.",
                        symbol: "magnifyingglass"
                    )
                    .padding(16)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredFigures, id: \.id) { figure in
                            NavigationLink {
                                FigureDetailView(figure: figure, store: store)
                            } label: {
                                CollectionFigureTile(
                                    figure: figure,
                                    owned: store.isOwned(figure.id, items: collection),
                                    wishlisted: store.isWishlisted(figure.id, items: wishlist)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }
            }
            .padding(.top, 10)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.secondaryText)
            TextField("Find a trooper...", text: $searchText)
                .textInputAutocapitalization(.never)
                .font(AppTheme.labelFont(size: 15, weight: .medium))
        }
        .padding(12)
        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var filteredFigures: [CatalogFigure] {
        let ownedIDs = store.ownedIDs(in: collection)
        return repository.search(searchText, in: figures)
            .filter { figure in
                (selectedEra == nil || figure.era == selectedEra) &&
                (selectedScope == .allCatalog || ownedIDs.contains(figure.id))
            }
    }

    private func filterChip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.labelFont(size: 14, weight: active ? .bold : .medium))
                .foregroundStyle(active ? .white : AppTheme.secondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(active ? AppTheme.accent : AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(active ? .white.opacity(0.1) : AppTheme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func shortEra(_ era: FigureEra) -> String {
        switch era {
        case .prequel: "Republic"
        case .cloneWars: "Clone Wars"
        case .original: "Empire"
        case .sequel: "Resistance"
        case .mando: "Mandalorian"
        case .gamingGreats: "Gaming Greats"
        }
    }
}

struct FigureDetailView: View {
    let figure: CatalogFigure
    let store: CollectionStore

    @Environment(\.dismiss) private var dismiss
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
            VStack(alignment: .leading, spacing: 18) {
                FigureHeroCard(figure: figure, owned: ownedItem != nil, wishlisted: wishItem != nil)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                statusToggle(owned: ownedItem != nil, wished: wishItem != nil)
                    .padding(.horizontal, 16)

                infoSection(
                    title: "Figure Lore",
                    icon: "book.closed",
                    content: AnyView(
                        Text(figure.lore)
                            .font(AppTheme.labelFont(size: 15))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineSpacing(4)
                    )
                )

                specsSection

                if ownedItem != nil {
                    ownedEditor
                }

                if wishItem != nil {
                    wishlistEditor
                }
            }
            .padding(.bottom, 112)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.profileBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            detailHeader
        }
        .task(id: collection.count + wishlist.count) {
            syncFormState()
        }
    }

    private var detailHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Back")

            Text("Figure Details")
                .font(AppTheme.displayFont(size: 18, weight: .bold))
                .frame(maxWidth: .infinity)

            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Share \(figure.name)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppTheme.profileBackground.opacity(0.95))
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.border).frame(height: 1)
        }
    }

    private var shareText: String {
        "\(figure.name)\n\(figure.subtitle)\n\(figure.line)\n\(figure.wave)"
    }

    private func statusToggle(owned: Bool, wished: Bool) -> some View {
        HStack(spacing: 4) {
            Button {
                try? store.toggleOwned(figure: figure, in: collection, context: modelContext)
                syncFormState()
            } label: {
                Label("Owned", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .foregroundStyle(owned ? .black : AppTheme.secondaryText)
                    .background(owned ? AppTheme.electric : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Button {
                try? store.toggleWishlist(figure: figure, in: wishlist, context: modelContext)
                syncFormState()
            } label: {
                Label("Wishlist", systemImage: "heart.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .foregroundStyle(wished ? .black : AppTheme.secondaryText)
                    .background(wished ? AppTheme.electric : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .font(AppTheme.labelFont(size: 14, weight: .bold))
        .padding(4)
        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
        .buttonStyle(.plain)
    }

    private var specsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailSectionHeader(title: "Specifications", icon: "slider.horizontal.3")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                specCard("Wave", figure.wave)
                specCard("Release Year", "\(figure.releaseYear)")
                specCard("Price", figure.msrp.currencyString)
                specCard("Faction", figure.faction.rawValue)
            }
        }
        .padding(.horizontal, 16)
    }

    private var ownedEditor: some View {
        infoSection(
            title: "Owned Status",
            icon: "backpack",
            content: AnyView(
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Condition", selection: $selectedStatus) {
                        ForEach(CollectionStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("Acquired from", text: $collectionSource)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    PriceField(title: "Purchase price", value: $purchasePrice)

                    Toggle("Favorite display piece", isOn: $favorite)
                        .tint(AppTheme.electric)

                    TextField("Collection notes", text: $collectionNotes, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                        .padding(12)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))

                    Button("Save Owned Details") {
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
            )
        )
    }

    private var wishlistEditor: some View {
        infoSection(
            title: "Wishlist Tracking",
            icon: "bell",
            content: AnyView(
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        PriceField(title: "Target price", value: $targetPrice)
                        PriceField(title: "Last seen", value: $lastKnownPrice)
                    }

                    TextField("Wishlist notes", text: $wishlistNotes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .padding(12)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Button("Save Watch Details") {
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
                    .tint(AppTheme.electric)
                    .foregroundStyle(.black)
                }
            )
        )
    }

    private func infoSection(title: String, icon: String, content: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailSectionHeader(title: title, icon: icon)
            content
                .padding(14)
                .background(AppTheme.elevatedSurface.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
        }
        .padding(.horizontal, 16)
    }

    private func specCard(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(AppTheme.labelFont(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(AppTheme.displayFont(size: 17, weight: .bold))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.elevatedSurface.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
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

private struct CollectionFigureTile: View {
    let figure: CatalogFigure
    let owned: Bool
    let wishlisted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                StitchFigureArtwork(figure: figure, contentMode: .fill)
                    .frame(height: 190)
                    .clipped()

                if owned {
                    StatusChip(title: "Owned", color: AppTheme.success)
                        .padding(8)
                } else if wishlisted {
                    StatusChip(title: "Wishlist", color: Color(hex: "#C084FC"))
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(figure.name)
                    .font(AppTheme.labelFont(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)

                Text(figure.wave)
                    .font(AppTheme.labelFont(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.electric)
                    .lineLimit(1)

                Text(figure.faction.rawValue)
                    .font(AppTheme.labelFont(size: 12))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 2)
        }
        .padding(8)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.elevatedSurface, lineWidth: 1))
    }
}

private struct DetailSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
            Text(title.uppercased())
                .font(AppTheme.labelFont(size: 13, weight: .bold))
                .tracking(1.5)
        }
        .foregroundStyle(AppTheme.accent)
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
