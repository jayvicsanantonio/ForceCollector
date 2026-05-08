import Foundation
import SwiftData

struct CatalogRepository {
    func loadSeedCatalog(bundle: Bundle = .main) throws -> [CatalogSeed] {
        guard let url = resolveSeedCatalogURL(preferredBundle: bundle) else {
            return Self.fallbackSeeds
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([CatalogSeed].self, from: data)
    }

    func figure(withID id: String, in figures: [CatalogFigure]) -> CatalogFigure? {
        figures.first(where: { $0.id == id })
    }

    func figures(for ids: [String], in figures: [CatalogFigure]) -> [CatalogFigure] {
        let map = Dictionary(uniqueKeysWithValues: figures.map { ($0.id, $0) })
        return ids.compactMap { map[$0] }
    }

    func search(_ query: String, in figures: [CatalogFigure]) -> [CatalogFigure] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized.isEmpty == false else {
            return figures.sorted(by: { $0.sortIndex < $1.sortIndex })
        }

        return figures
            .filter {
                $0.name.lowercased().contains(normalized) ||
                $0.subtitle.lowercased().contains(normalized) ||
                $0.line.lowercased().contains(normalized) ||
                $0.wave.lowercased().contains(normalized)
            }
            .sorted(by: { $0.sortIndex < $1.sortIndex })
    }

    func matchBarcode(_ barcode: String, in figures: [CatalogFigure]) -> CatalogFigure? {
        let normalized = normalizeBarcode(barcode)
        return figures.first(where: { normalizeBarcode($0.barcode ?? "") == normalized })
    }

    func normalizeBarcode(_ code: String) -> String {
        code.filter(\.isNumber)
    }

    private func resolveSeedCatalogURL(preferredBundle: Bundle) -> URL? {
        let candidates = [preferredBundle, Bundle.main, Bundle(for: BundleLocator.self)] + Bundle.allBundles + Bundle.allFrameworks

        for candidate in candidates {
            if let url = candidate.url(forResource: "SeedCatalog", withExtension: "json") {
                return url
            }
            if let url = candidate.url(forResource: "SeedCatalog", withExtension: "json", subdirectory: "Resources") {
                return url
            }
        }

        return nil
    }

    enum CatalogError: Error {
        case missingSeedCatalog
    }

    private final class BundleLocator {}

    private static let fallbackSeeds: [CatalogSeed] = [
        CatalogSeed(id: "archive-luke-skywalker", name: "Luke Skywalker", subtitle: "Jedi Knight (Archive)", line: "Black Series Archive", wave: "Archive Wave 4", faction: .jedi, era: .original, lore: "Luke stands at the center of the Rebellion mythos, balancing hope, discipline, and the weight of legacy as he grows from farm boy to Jedi Knight.", releaseYear: 2022, msrp: 24.99, barcode: "5010993957140", accentHex: "#3B82F6", symbol: "sparkles", sortIndex: 1),
        CatalogSeed(id: "darth-vader-obiwan", name: "Darth Vader", subtitle: "Obi-Wan Kenobi", line: "Black Series", wave: "Kenobi Wave", faction: .sith, era: .original, lore: "Vader projects raw Imperial menace, a collector centerpiece whose visual power comes from silhouette, restraint, and relentless presence.", releaseYear: 2023, msrp: 27.99, barcode: "5010996145483", accentHex: "#EF4444", symbol: "flame.fill", sortIndex: 2),
        CatalogSeed(id: "mando-ahsoka-tano", name: "Ahsoka Tano", subtitle: "The Mandalorian", line: "Black Series", wave: "Mando Wave 12", faction: .jedi, era: .mando, lore: "Ahsoka bridges eras and fan generations, bringing dual-saber elegance and deep Clone Wars history into the post-Empire frontier.", releaseYear: 2024, msrp: 27.99, barcode: "5010996221033", accentHex: "#34D399", symbol: "bolt.horizontal.circle.fill", sortIndex: 3),
        CatalogSeed(id: "captain-rex-clone-wars", name: "Captain Rex", subtitle: "Phase II Armor", line: "Black Series", wave: "Clone Wars Anniversary", faction: .cloneTrooper, era: .cloneWars, lore: "Rex represents disciplined leadership and battle-worn loyalty, making him a cornerstone figure for Clone Wars shelves.", releaseYear: 2023, msrp: 27.99, barcode: "5010996132193", accentHex: "#60A5FA", symbol: "shield.lefthalf.filled", sortIndex: 4),
        CatalogSeed(id: "bo-katan-kryze", name: "Bo-Katan Kryze", subtitle: "Mandalorian Loyalist", line: "Black Series", wave: "Mando Wave 9", faction: .mandalorian, era: .mando, lore: "Bo-Katan anchors Mandalorian display lines with royal armor, leadership tension, and a striking blue-and-silver visual identity.", releaseYear: 2022, msrp: 26.49, barcode: "5010993957034", accentHex: "#2563EB", symbol: "person.crop.rectangle.stack.fill", sortIndex: 5),
        CatalogSeed(id: "han-solo-endor", name: "Han Solo", subtitle: "Endor", line: "Return of the Jedi 40th", wave: "ROTJ Deluxe", faction: .scoundrel, era: .original, lore: "Han’s Endor look mixes rugged practicality with command energy, perfect for collectors building battle-of-Endor storytelling shelves.", releaseYear: 2023, msrp: 27.99, barcode: "5010996145506", accentHex: "#F59E0B", symbol: "scope", sortIndex: 6),
        CatalogSeed(id: "moff-gideon-dark-trooper-armor", name: "Moff Gideon", subtitle: "Dark Trooper Armor", line: "Black Series", wave: "Mando Villains", faction: .empire, era: .mando, lore: "Gideon’s armored variant is pure shelf drama, designed for collector impact with angular plating and authoritarian menace.", releaseYear: 2024, msrp: 29.99, barcode: "5010996240010", accentHex: "#9333EA", symbol: "crown.fill", sortIndex: 7),
        CatalogSeed(id: "cal-kestis-gaming-greats", name: "Cal Kestis", subtitle: "Gaming Greats", line: "Gaming Greats", wave: "Jedi Survivor", faction: .jedi, era: .gamingGreats, lore: "Cal brings modern game-era storytelling into Black Series form, blending weathered gear, focused posture, and survivor grit.", releaseYear: 2023, msrp: 27.99, barcode: nil, accentHex: "#8B5CF6", symbol: "gamecontroller.fill", sortIndex: 8),
        CatalogSeed(id: "boba-fett-tython", name: "Boba Fett", subtitle: "Tython Armor", line: "Black Series Deluxe", wave: "Mando Deluxe", faction: .bountyHunter, era: .mando, lore: "Battle-scarred armor, decisive stance, and massive fan appeal make this Boba an easy centerpiece for any modern bounty shelf.", releaseYear: 2022, msrp: 33.99, barcode: "5010993957157", accentHex: "#22C55E", symbol: "target", sortIndex: 9),
        CatalogSeed(id: "rey-jedi-training", name: "Rey", subtitle: "Jedi Training", line: "Black Series", wave: "Sequel Wave 5", faction: .resistance, era: .sequel, lore: "Rey’s training-era design gives sequel displays a grounded, transitional look with strong silhouette clarity and staff-to-saber lineage.", releaseYear: 2021, msrp: 24.99, barcode: nil, accentHex: "#FB7185", symbol: "sun.max.fill", sortIndex: 10),
        CatalogSeed(id: "stormtrooper-jedha-patrol", name: "Stormtrooper", subtitle: "Jedha Patrol", line: "Andor / Rogue One", wave: "Imperial Patrol", faction: .empire, era: .original, lore: "A patrol trooper variant adds texture to Imperial shelves, giving army builders another strong silhouette and world-building beat.", releaseYear: 2024, msrp: 27.99, barcode: "5010996240058", accentHex: "#94A3B8", symbol: "shield.fill", sortIndex: 11),
        CatalogSeed(id: "battle-droid-geonosis", name: "B1 Battle Droid", subtitle: "Geonosis", line: "Black Series", wave: "Prequel Arena", faction: .droid, era: .prequel, lore: "The B1 battle droid adds classic prequel battlefield texture, especially for collectors building Geonosis or CIS displays.", releaseYear: 2022, msrp: 25.99, barcode: nil, accentHex: "#F97316", symbol: "cpu.fill", sortIndex: 12)
    ]
}

enum CatalogSeeder {
    static func seedIfNeeded(context: ModelContext, repository: CatalogRepository = CatalogRepository()) throws {
        let descriptor = FetchDescriptor<CatalogFigure>()
        let existingCount = try context.fetchCount(descriptor)
        guard existingCount == 0 else { return }

        let seeds = try repository.loadSeedCatalog()
        for seed in seeds {
            context.insert(CatalogFigure(seed: seed))
        }
        try context.save()
    }
}

struct CollectionStore {
    func item(for figureID: String, in items: [CollectionItem]) -> CollectionItem? {
        items.first(where: { $0.figureID == figureID })
    }

    func wishlistItem(for figureID: String, in items: [WishlistItem]) -> WishlistItem? {
        items.first(where: { $0.figureID == figureID })
    }

    func isOwned(_ figureID: String, items: [CollectionItem]) -> Bool {
        item(for: figureID, in: items) != nil
    }

    func isWishlisted(_ figureID: String, items: [WishlistItem]) -> Bool {
        wishlistItem(for: figureID, in: items) != nil
    }

    func ownedIDs(in items: [CollectionItem]) -> Set<String> {
        Set(items.map(\.figureID))
    }

    func toggleOwned(figure: CatalogFigure, in items: [CollectionItem], context: ModelContext) throws {
        if let existing = item(for: figure.id, in: items) {
            context.delete(existing)
        } else {
            context.insert(CollectionItem(figureID: figure.id, status: .sealed, purchasePrice: figure.msrp))
        }
        try context.save()
    }

    func updateCollectionItem(
        figureID: String,
        items: [CollectionItem],
        context: ModelContext,
        status: CollectionStatus,
        source: String,
        notes: String,
        purchasePrice: Double?,
        isFavorite: Bool
    ) throws {
        guard let item = item(for: figureID, in: items) else { return }
        item.status = status
        item.source = source
        item.notes = notes
        item.purchasePrice = purchasePrice
        item.isFavorite = isFavorite
        try context.save()
    }

    func toggleWishlist(figure: CatalogFigure, in items: [WishlistItem], context: ModelContext) throws {
        if let existing = wishlistItem(for: figure.id, in: items) {
            context.delete(existing)
        } else {
            context.insert(WishlistItem(figureID: figure.id, targetPrice: figure.msrp))
        }
        try context.save()
    }

    func updateWishlist(
        figureID: String,
        items: [WishlistItem],
        context: ModelContext,
        targetPrice: Double?,
        lastKnownPrice: Double?,
        notes: String
    ) throws {
        guard let item = wishlistItem(for: figureID, in: items) else { return }
        item.targetPrice = targetPrice
        item.lastKnownPrice = lastKnownPrice
        item.notes = notes
        item.lastUpdatedAt = .now
        try context.save()
    }

    func recordScan(code: String, matchedFigureID: String?, query: String, context: ModelContext) throws {
        context.insert(ScanRecord(scannedCode: code, matchedFigureID: matchedFigureID, manualQuery: query))
        try context.save()
    }

    func resetUserData(context: ModelContext) throws {
        try context.delete(model: CollectionItem.self)
        try context.delete(model: WishlistItem.self)
        try context.delete(model: ScanRecord.self)
        try context.save()
    }

    func reseedCatalog(context: ModelContext, repository: CatalogRepository = CatalogRepository()) throws {
        try context.delete(model: CatalogFigure.self)
        try context.save()
        try CatalogSeeder.seedIfNeeded(context: context, repository: repository)
    }
}

struct ScanLookupResult {
    var matchedFigure: CatalogFigure?
    var suggestedFigures: [CatalogFigure]
    var query: String
}

struct ScannerService {
    private let repository = CatalogRepository()

    func resolveScan(code: String, in figures: [CatalogFigure]) -> ScanLookupResult {
        if let match = repository.matchBarcode(code, in: figures) {
            return ScanLookupResult(matchedFigure: match, suggestedFigures: [], query: code)
        }

        let suggestions = repository.search(code, in: figures)
        return ScanLookupResult(matchedFigure: nil, suggestedFigures: Array(suggestions.prefix(4)), query: code)
    }
}

struct AnalyticsSnapshot {
    let totalCatalog: Int
    let ownedCount: Int
    let wishlistCount: Int
    let completionRatio: Double
    let favoriteCount: Int
    let averageOwnedPrice: Double
    let byEra: [(FigureEra, Int)]
    let byStatus: [(CollectionStatus, Int)]
    let recentWishlistValue: Double
}

struct AnalyticsService {
    func snapshot(
        figures: [CatalogFigure],
        collection: [CollectionItem],
        wishlist: [WishlistItem]
    ) -> AnalyticsSnapshot {
        let catalogMap = Dictionary(uniqueKeysWithValues: figures.map { ($0.id, $0) })
        let ownedCount = collection.count
        let totalCatalog = figures.count
        let favoriteCount = collection.filter(\.isFavorite).count
        let completionRatio = totalCatalog == 0 ? 0 : Double(ownedCount) / Double(totalCatalog)
        let averageOwnedPrice = collection.compactMap(\.purchasePrice).average
        let byEra = Dictionary(grouping: collection, by: { item in
            catalogMap[item.figureID]?.era ?? .original
        })
        .map { ($0.key, $0.value.count) }
        .sorted { $0.1 > $1.1 }

        let byStatus = Dictionary(grouping: collection, by: \.status)
            .map { ($0.key, $0.value.count) }
            .sorted { $0.0.rawValue < $1.0.rawValue }

        let recentWishlistValue = wishlist.compactMap(\.lastKnownPrice).reduce(0, +)

        return AnalyticsSnapshot(
            totalCatalog: totalCatalog,
            ownedCount: ownedCount,
            wishlistCount: wishlist.count,
            completionRatio: completionRatio,
            favoriteCount: favoriteCount,
            averageOwnedPrice: averageOwnedPrice,
            byEra: byEra,
            byStatus: byStatus,
            recentWishlistValue: recentWishlistValue
        )
    }
}

private extension Array where Element == Double {
    var average: Double {
        guard isEmpty == false else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
