import SwiftData
import SwiftUI

@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        do {
            let schema = Schema([CatalogFigure.self, CollectionItem.self, WishlistItem.self, ScanRecord.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: configuration)
            try CatalogSeeder.seedIfNeeded(context: container.mainContext)

            let collection = CollectionItem(
                figureID: "archive-luke-skywalker",
                status: .displayed,
                purchasePrice: 24.99,
                source: "Preview Shelf",
                notes: "Great face print.",
                isFavorite: true
            )
            let wishlist = WishlistItem(
                figureID: "mando-ahsoka-tano",
                targetPrice: 29.99,
                lastKnownPrice: 37.50,
                notes: "Wait for a convention sale."
            )
            container.mainContext.insert(collection)
            container.mainContext.insert(wishlist)
            try container.mainContext.save()
            return container
        } catch {
            fatalError("Preview container failed: \(error)")
        }
    }()
}
