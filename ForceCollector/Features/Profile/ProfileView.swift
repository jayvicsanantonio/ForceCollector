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
        StitchScreen(title: "Profile & Settings", trailingIcon: "gearshape.fill") {
            VStack(spacing: 22) {
                profileCard

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "circle.lefthalf.filled")
                                .foregroundStyle(AppTheme.secondaryText)
                            Text("Allegiance (Theme)")
                                .font(AppTheme.labelFont(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.secondaryText)
                                .tracking(1.1)
                                .textCase(.uppercase)
                        }

                        HStack(spacing: 6) {
                            allegianceOption(title: "Light Side", color: AppTheme.accent, selected: false)
                            allegianceOption(title: "Dark Side", color: AppTheme.danger, selected: true)
                        }
                        .padding(6)
                        .background(AppTheme.profileBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal, 16)

                settingsList
                    .padding(.horizontal, 16)

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Display Preferences")
                            .font(AppTheme.displayFont(size: 17, weight: .bold))

                        Toggle("Show lore emphasis", isOn: $showLoreOnCards)
                        Toggle("Highlight wishlist", isOn: $highlightWishlist)
                        Toggle("Reduce ambient glow", isOn: $reduceGlow)
                    }
                }
                .padding(.horizontal, 16)

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Catalog Controls")
                            .font(AppTheme.displayFont(size: 17, weight: .bold))

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
                .padding(.horizontal, 16)

                Button {
                    // TODO: Implement account logout when authentication exists.
                } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(AppTheme.labelFont(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.danger)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(true)
                .opacity(0.5)
                .padding(.horizontal, 16)

                Text("App Version 2.4.1 (Build 1138)")
                    .font(AppTheme.labelFont(size: 12))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.top, 16)
        }
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

    private var profileCard: some View {
        CollectorPanel {
            VStack(spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    StitchRemoteImage(urlString: StitchAsset.profile, contentMode: .fill)
                        .frame(width: 112, height: 112)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.elevatedSurface, lineWidth: 4))

                    Image(systemName: "medal.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(7)
                        .background(AppTheme.accent, in: Circle())
                        .overlay(Circle().stroke(AppTheme.elevatedSurface, lineWidth: 2))
                }

                VStack(spacing: 4) {
                    Text("Commander Cody")
                        .font(AppTheme.displayFont(size: 24, weight: .bold))
                    Text("Level 54: Grand Admiral")
                        .font(AppTheme.labelFont(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                VStack(spacing: 8) {
                    HStack {
                        Text("XP to next rank")
                            .font(AppTheme.labelFont(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.secondaryText)
                            .tracking(0.7)
                            .textCase(.uppercase)
                        Spacer()
                        Text("1500 / 2000")
                            .font(AppTheme.labelFont(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 999).fill(AppTheme.background)
                            RoundedRectangle(cornerRadius: 999)
                                .fill(LinearGradient(colors: [Color(hex: "#2563EB"), AppTheme.accent], startPoint: .leading, endPoint: .trailing))
                                .frame(width: proxy.size.width * 0.75)
                                .shadow(color: AppTheme.accent.opacity(0.55), radius: 12)
                        }
                    }
                    .frame(height: 12)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .overlay(alignment: .top) {
            LinearGradient(colors: [.clear, AppTheme.accent.opacity(0.55), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
    }

    private var settingsList: some View {
        VStack(spacing: 0) {
            settingsRow(title: "Notifications", icon: "bell.fill")
            Divider().overlay(AppTheme.border)
            settingsRow(title: "Account Details", icon: "person.crop.circle")
            Divider().overlay(AppTheme.border)
            settingsRow(title: "Privacy Policy", icon: "shield.fill")
        }
        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))
    }

    private func settingsRow(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 32, height: 32)
                .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(title)
                .font(AppTheme.labelFont(size: 15, weight: .medium))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(14)
    }

    private func allegianceOption(title: String, color: Color, selected: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Capsule()
                    .fill(AppTheme.secondaryText.opacity(0.18))
                    .frame(height: 6)
                Capsule()
                    .fill(color)
                    .frame(height: 6)
                    .shadow(color: color.opacity(0.5), radius: selected ? 8 : 0)
                    .opacity(selected ? 1 : 0.35)
            }

            HStack(spacing: 6) {
                Text(title)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                }
            }
            .font(AppTheme.labelFont(size: 14, weight: selected ? .bold : .medium))
            .foregroundStyle(selected ? AppTheme.accent : AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(selected ? AppTheme.elevatedSurface : .clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? AppTheme.border : .clear, lineWidth: 1))
    }
}
