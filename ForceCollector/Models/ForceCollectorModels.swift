import Foundation
import SwiftData

enum FigureFaction: String, Codable, CaseIterable, Identifiable {
    case jedi = "Jedi"
    case sith = "Sith"
    case rebellion = "Rebellion"
    case empire = "Empire"
    case mandalorian = "Mandalorian"
    case bountyHunter = "Bounty Hunter"
    case cloneTrooper = "Clone Trooper"
    case droid = "Droid"
    case firstOrder = "First Order"
    case resistance = "Resistance"
    case scoundrel = "Scoundrel"

    var id: String { rawValue }
}

enum FigureEra: String, Codable, CaseIterable, Identifiable {
    case prequel = "Prequel Trilogy"
    case cloneWars = "The Clone Wars"
    case original = "Original Trilogy"
    case sequel = "Sequel Trilogy"
    case mando = "The Mandalorian"
    case gamingGreats = "Gaming Greats"

    var id: String { rawValue }
}

enum CollectionStatus: String, Codable, CaseIterable, Identifiable {
    case sealed = "Sealed"
    case opened = "Opened"
    case displayed = "Displayed"
    case archived = "Archived"

    var id: String { rawValue }
}

enum CollectionScope: String, CaseIterable, Identifiable {
    case owned = "Owned"
    case allCatalog = "Catalog"

    var id: String { rawValue }
}

struct CatalogSeed: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let line: String
    let wave: String
    let faction: FigureFaction
    let era: FigureEra
    let lore: String
    let releaseYear: Int
    let msrp: Double
    let barcode: String?
    let accentHex: String
    let symbol: String
    let sortIndex: Int
}

@Model
final class CatalogFigure {
    @Attribute(.unique) var id: String
    var name: String
    var subtitle: String
    var line: String
    var wave: String
    var factionRawValue: String
    var eraRawValue: String
    var lore: String
    var releaseYear: Int
    var msrp: Double
    var barcode: String?
    var accentHex: String
    var symbol: String
    var sortIndex: Int

    init(seed: CatalogSeed) {
        id = seed.id
        name = seed.name
        subtitle = seed.subtitle
        line = seed.line
        wave = seed.wave
        factionRawValue = seed.faction.rawValue
        eraRawValue = seed.era.rawValue
        lore = seed.lore
        releaseYear = seed.releaseYear
        msrp = seed.msrp
        barcode = seed.barcode
        accentHex = seed.accentHex
        symbol = seed.symbol
        sortIndex = seed.sortIndex
    }

    var faction: FigureFaction {
        FigureFaction(rawValue: factionRawValue) ?? .scoundrel
    }

    var era: FigureEra {
        FigureEra(rawValue: eraRawValue) ?? .original
    }
}

@Model
final class CollectionItem {
    @Attribute(.unique) var figureID: String
    var statusRawValue: String
    var acquiredAt: Date
    var purchasePrice: Double?
    var source: String
    var notes: String
    var isFavorite: Bool

    init(
        figureID: String,
        status: CollectionStatus = .sealed,
        acquiredAt: Date = .now,
        purchasePrice: Double? = nil,
        source: String = "Local Shop",
        notes: String = "",
        isFavorite: Bool = false
    ) {
        self.figureID = figureID
        statusRawValue = status.rawValue
        self.acquiredAt = acquiredAt
        self.purchasePrice = purchasePrice
        self.source = source
        self.notes = notes
        self.isFavorite = isFavorite
    }

    var status: CollectionStatus {
        get { CollectionStatus(rawValue: statusRawValue) ?? .sealed }
        set { statusRawValue = newValue.rawValue }
    }
}

@Model
final class WishlistItem {
    @Attribute(.unique) var figureID: String
    var addedAt: Date
    var targetPrice: Double?
    var lastKnownPrice: Double?
    var lastUpdatedAt: Date
    var notes: String

    init(
        figureID: String,
        addedAt: Date = .now,
        targetPrice: Double? = nil,
        lastKnownPrice: Double? = nil,
        lastUpdatedAt: Date = .now,
        notes: String = ""
    ) {
        self.figureID = figureID
        self.addedAt = addedAt
        self.targetPrice = targetPrice
        self.lastKnownPrice = lastKnownPrice
        self.lastUpdatedAt = lastUpdatedAt
        self.notes = notes
    }
}

@Model
final class ScanRecord {
    var scannedCode: String
    var matchedFigureID: String?
    var createdAt: Date
    var manualQuery: String

    init(scannedCode: String, matchedFigureID: String?, createdAt: Date = .now, manualQuery: String = "") {
        self.scannedCode = scannedCode
        self.matchedFigureID = matchedFigureID
        self.createdAt = createdAt
        self.manualQuery = manualQuery
    }
}
