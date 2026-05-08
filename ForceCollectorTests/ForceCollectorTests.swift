import SwiftData
import Testing
@testable import ForceCollector

@MainActor
struct ForceCollectorTests {
    @Test
    func seedCatalogImportsOnce() throws {
        let container = try makeContainer()
        let repository = CatalogRepository()

        try CatalogSeeder.seedIfNeeded(context: container.mainContext, repository: repository)
        try CatalogSeeder.seedIfNeeded(context: container.mainContext, repository: repository)

        let figures = try container.mainContext.fetch(FetchDescriptor<CatalogFigure>())
        #expect(figures.count == 12)
    }

    @Test
    func collectionToggleAndAnalyticsUpdate() throws {
        let container = try makeContainer()
        try CatalogSeeder.seedIfNeeded(context: container.mainContext)
        let figures = try container.mainContext.fetch(FetchDescriptor<CatalogFigure>())
        let store = CollectionStore()

        try store.toggleOwned(figure: figures[0], in: [], context: container.mainContext)
        let collection = try container.mainContext.fetch(FetchDescriptor<CollectionItem>())
        let snapshot = AnalyticsService().snapshot(figures: figures, collection: collection, wishlist: [])

        #expect(collection.count == 1)
        #expect(snapshot.ownedCount == 1)
    }

    @Test
    func repositorySearchAndBarcodeMatch() throws {
        let container = try makeContainer()
        try CatalogSeeder.seedIfNeeded(context: container.mainContext)
        let figures = try container.mainContext.fetch(FetchDescriptor<CatalogFigure>())
        let repository = CatalogRepository()

        let searchResults = repository.search("ahsoka", in: figures)
        let barcodeMatch = repository.matchBarcode("5010996145483", in: figures)

        #expect(searchResults.first?.name == "Ahsoka Tano")
        #expect(barcodeMatch?.name == "Darth Vader")
    }

    @Test
    func wishlistUpdatesPersist() throws {
        let container = try makeContainer()
        try CatalogSeeder.seedIfNeeded(context: container.mainContext)
        let figures = try container.mainContext.fetch(FetchDescriptor<CatalogFigure>())
        let store = CollectionStore()

        try store.toggleWishlist(figure: figures[1], in: [], context: container.mainContext)
        let firstPass = try container.mainContext.fetch(FetchDescriptor<WishlistItem>())
        try store.updateWishlist(
            figureID: figures[1].id,
            items: firstPass,
            context: container.mainContext,
            targetPrice: 21.99,
            lastKnownPrice: 32.50,
            notes: "Watch convention exclusives"
        )

        let wishlist = try container.mainContext.fetch(FetchDescriptor<WishlistItem>())
        #expect(wishlist.first?.targetPrice == 21.99)
        #expect(wishlist.first?.notes == "Watch convention exclusives")
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([CatalogFigure.self, CollectionItem.self, WishlistItem.self, ScanRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
