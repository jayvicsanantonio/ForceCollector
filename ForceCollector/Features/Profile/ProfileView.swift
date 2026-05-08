import SwiftData
import SwiftUI

struct ProfileView: View {
    let store: CollectionStore

    @Environment(\.modelContext) private var modelContext

    @AppStorage("pref_showLoreOnCards") private var showLoreOnCards = true
    @AppStorage("pref_highlightWishlist") private var highlightWishlist = true
    @AppStorage("pref_reduceGlow") private var reduceGlow = false

    @State private var confirmReset = false
    @State private var confirmReseed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionTitle(
                    eyebrow: "Collector ID",
                    title: "Profile & Settings",
                    subtitle: "Tune display preferences, manage local data, and reserve room for later import or sync."
                )

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Display preferences")
                            .font(.system(.headline, design: .rounded, weight: .semibold))

                        Toggle("Show lore emphasis in detail views", isOn: $showLoreOnCards)
                        Toggle("Highlight wishlisted figures in grids", isOn: $highlightWishlist)
                        Toggle("Reduce ambient glow effects", isOn: $reduceGlow)
                    }
                }

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Catalog controls")
                            .font(.system(.headline, design: .rounded, weight: .semibold))

                        Button("Reseed starter catalog") {
                            confirmReseed = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accent)

                        Button("Reset owned, wishlist, and scan history") {
                            confirmReset = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.danger)
                    }
                }

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Future expansion")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                        Text("Import, export, and cloud sync are intentionally held for a later release. This MVP keeps everything local and fast.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.background)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Reset local user data?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) {
                try? store.resetUserData(context: modelContext)
            }
        } message: {
            Text("This clears owned figures, wishlist entries, and scan history but keeps the seeded catalog.")
        }
        .confirmationDialog("Reseed the starter catalog?", isPresented: $confirmReseed) {
            Button("Reseed", role: .destructive) {
                try? store.reseedCatalog(context: modelContext)
            }
        } message: {
            Text("This rebuilds the local starter catalog from the bundled JSON.")
        }
    }
}
