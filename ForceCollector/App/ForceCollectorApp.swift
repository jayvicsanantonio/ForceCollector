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
                .tag(AppTab.home)
                .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.icon) }

                NavigationStack {
                    CollectionGridView(store: store)
                }
                .tag(AppTab.collection)
                .tabItem { Label(AppTab.collection.title, systemImage: AppTab.collection.icon) }

                NavigationStack {
                    WishlistView(store: store)
                }
                .tag(AppTab.wishlist)
                .tabItem { Label(AppTab.wishlist.title, systemImage: AppTab.wishlist.icon) }

                NavigationStack {
                    ScanView(store: store)
                }
                .tag(AppTab.scan)
                .tabItem { Label(AppTab.scan.title, systemImage: AppTab.scan.icon) }

                NavigationStack {
                    ProfileView(store: store)
                }
                .tag(AppTab.profile)
                .tabItem { Label(AppTab.profile.title, systemImage: AppTab.profile.icon) }
            }
            .toolbar(.hidden, for: .tabBar)

            VStack {
                Spacer()
                StitchTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)

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

enum AppTab: Hashable, CaseIterable {
    case home
    case collection
    case scan
    case wishlist
    case profile

    static let allCases: [AppTab] = [.home, .collection, .wishlist, .scan, .profile]
}

private struct SplashView: View {
    var body: some View {
        ZStack {
            StitchRemoteImage(urlString: StitchAsset.splash, contentMode: .fill)
                .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.15), AppTheme.background.opacity(0.72), AppTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Force Collector")
                        .font(AppTheme.displayFont(size: 38, weight: .bold))

                    Text("Your Black Series command center")
                        .font(AppTheme.labelFont(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.electric)
                        .tracking(1.2)
                        .textCase(.uppercase)
                }

                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == 1 ? AppTheme.electric : .white.opacity(0.35))
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()
                    .frame(height: 84)
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
