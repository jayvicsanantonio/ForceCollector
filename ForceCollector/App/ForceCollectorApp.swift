import SwiftData
import SwiftUI

@main
struct ForceCollectorApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                CatalogFigure.self,
                CollectionItem.self,
                WishlistItem.self,
                ScanRecord.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: configuration)
            try CatalogSeeder.seedIfNeeded(context: modelContainer.mainContext)
        } catch {
            fatalError("Unable to bootstrap Force Collector: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ForceCollectorRootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
    }
}

struct ForceCollectorRootView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showSplash = true
    private let store = CollectionStore()

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                NavigationStack {
                    DashboardView(store: store, selectedTab: $selectedTab)
                }
                .tabItem {
                    Label("Home", systemImage: "sparkles.square.filled.on.square")
                }
                .tag(AppTab.home)

                NavigationStack {
                    CollectionGridView(store: store)
                }
                .tabItem {
                    Label("Collection", systemImage: "square.grid.2x2.fill")
                }
                .tag(AppTab.collection)

                NavigationStack {
                    ScanView(store: store)
                }
                .tabItem {
                    Label("Scan", systemImage: "barcode.viewfinder")
                }
                .tag(AppTab.scan)

                NavigationStack {
                    WishlistView(store: store)
                }
                .tabItem {
                    Label("Wishlist", systemImage: "star.bubble.fill")
                }
                .tag(AppTab.wishlist)

                NavigationStack {
                    ProfileView(store: store)
                }
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(AppTab.profile)
            }
            .tint(AppTheme.accent)

            if showSplash {
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeInOut(duration: 0.45)) {
                showSplash = false
            }
        }
    }
}

enum AppTab: Hashable {
    case home
    case collection
    case scan
    case wishlist
    case profile
}

private struct SplashView: View {
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            LinearGradient(
                colors: [AppTheme.accent.opacity(0.6), .clear, AppTheme.gold.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 36)
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "sparkles.tv.fill")
                    .font(.system(size: 52, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.gold, .white, AppTheme.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 8) {
                    Text("Force Collector")
                        .font(AppTheme.displayFont(size: 34, weight: .bold))
                        .tracking(0.5)

                    Text("Track every Black Series hunt, grail, and scan.")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == 1 ? AppTheme.gold : AppTheme.accent.opacity(0.7))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
