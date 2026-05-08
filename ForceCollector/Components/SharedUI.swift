import SwiftUI

struct StitchScreen<Content: View>: View {
    let title: String
    let trailingIcon: String
    let content: Content

    init(title: String, trailingIcon: String = "gearshape", @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailingIcon = trailingIcon
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                StitchHeader(title: title, trailingIcon: trailingIcon)
                content
            }
            .padding(.bottom, 110)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct StitchHeader: View {
    let title: String
    var subtitle: String?
    var trailingIcon: String = "gearshape"

    var body: some View {
        HStack(spacing: 12) {
            StitchRemoteImage(urlString: StitchAsset.avatar, contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppTheme.electric.opacity(0.45), lineWidth: 2))

            VStack(alignment: .leading, spacing: 2) {
                if let subtitle {
                    Text(subtitle.uppercased())
                        .font(AppTheme.labelFont(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.navIcon.opacity(0.7))
                }
                Text(title)
                    .font(AppTheme.displayFont(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.text)
            }

            Spacer()

            Image(systemName: trailingIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.electric)
                .frame(width: 40, height: 40)
                .background(AppTheme.surface, in: Circle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(AppTheme.background.opacity(0.96))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.elevatedSurface)
                .frame(height: 1)
        }
    }
}

struct CollectorPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}

struct SectionTitle: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(AppTheme.labelFont(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.electric)
                .tracking(1.3)

            Text(title)
                .font(AppTheme.displayFont(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.text)

            Text(subtitle)
                .font(AppTheme.labelFont(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(3)
        }
    }
}

struct MetricCard: View {
    let label: String
    let value: String
    let icon: String
    let accent: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTheme.displayFont(size: 24, weight: .bold))
                .foregroundStyle(accent == AppTheme.accent ? AppTheme.electric : AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(label.uppercased())
                .font(AppTheme.labelFont(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.navIcon.opacity(0.6))
                .tracking(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 78)
        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accent.opacity(0.16), lineWidth: 1)
        )
    }
}

struct StatusChip: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title.uppercased())
            .font(AppTheme.labelFont(size: 10, weight: .bold))
            .foregroundStyle(color)
            .tracking(0.6)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.35), lineWidth: 1))
    }
}

struct FigureHeroCard: View {
    let figure: CatalogFigure
    let owned: Bool
    let wishlisted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                StitchRemoteImage(urlString: StitchAsset.heroImage(for: figure), contentMode: .fill)
                    .frame(height: 420)
                    .clipped()

                LinearGradient(
                    colors: [.clear, AppTheme.background.opacity(0.24), AppTheme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )

                HStack(spacing: 8) {
                    if owned {
                        StatusChip(title: "Owned", color: AppTheme.success)
                    }
                    if wishlisted {
                        StatusChip(title: "Wishlist", color: AppTheme.gold)
                    }
                }
                .padding(14)

                VStack(spacing: 5) {
                    Spacer()
                    HStack(spacing: 6) {
                        Capsule().fill(AppTheme.accent).frame(width: 24, height: 5)
                        Circle().fill(.white.opacity(0.35)).frame(width: 5, height: 5)
                        Circle().fill(.white.opacity(0.35)).frame(width: 5, height: 5)
                        Circle().fill(.white.opacity(0.35)).frame(width: 5, height: 5)
                    }
                    .padding(.bottom, 18)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(figure.name)
                    .font(AppTheme.displayFont(size: 32, weight: .bold))
                    .foregroundStyle(AppTheme.text)

                Text(figure.subtitle)
                    .font(AppTheme.labelFont(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.top, 16)
            .padding(.horizontal, 4)
        }
    }
}

struct EmptyCollectorState: View {
    let title: String
    let message: String
    let symbol: String

    var body: some View {
        CollectorPanel {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.electric)

                Text(title)
                    .font(AppTheme.displayFont(size: 22, weight: .bold))

                Text(message)
                    .font(AppTheme.labelFont(size: 14))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}

struct PriceField: View {
    let title: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(AppTheme.labelFont(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)

            TextField("$0.00", text: $value)
                .keyboardType(.decimalPad)
                .font(AppTheme.labelFont(size: 15, weight: .semibold))
                .padding(12)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
        }
    }
}

struct StitchRemoteImage: View {
    let urlString: String
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            default:
                ZStack {
                    LinearGradient(
                        colors: [AppTheme.elevatedSurface, AppTheme.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "sparkles")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(AppTheme.electric.opacity(0.65))
                }
            }
        }
    }
}

struct StitchTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: selectedTab == tab ? .bold : .regular))
                        Text(tab.title)
                            .font(AppTheme.labelFont(size: 10, weight: selectedTab == tab ? .bold : .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(selectedTab == tab ? AppTheme.electric : AppTheme.secondaryText)
                    .overlay(alignment: .top) {
                        if selectedTab == tab {
                            Capsule()
                                .fill(AppTheme.electric)
                                .frame(width: 30, height: 2)
                                .offset(y: -11)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(AppTheme.background.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.border)
                .frame(height: 1)
        }
    }
}

extension AppTab {
    var title: String {
        switch self {
        case .home: "Home"
        case .collection: "Collection"
        case .scan: "Search"
        case .wishlist: "Wishlist"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: "house"
        case .collection: "square.grid.2x2"
        case .scan: "magnifyingglass"
        case .wishlist: "heart"
        case .profile: "person"
        }
    }
}

enum StitchAsset {
    static let avatar = "https://lh3.googleusercontent.com/aida-public/AB6AXuDJOakPs42-PcJbsAoeNYRRZFISqlXauRFUZJUNlWiFg6ne6F0eXNo0F8DfXGzPfPskNifU6NkeIw8zB2GBrL0ORrA4mxMZEeSO9m3Q6i09tSLiCetJ0DwUHWAgpYX4yONi__mGGQscTwAnJ7g6dt9e14j9RKShE628CEP7uxwJOm5KDzGiM1WHNVmaqVRlTJJn0XwGNA8yU5-nxH7P16UT9Sas0GB8d7HlFW9i-uk-ZPLika2l1x51INsDivbd6xRJgbEBSF-quq0"
    static let scanner = "https://lh3.googleusercontent.com/aida-public/AB6AXuD1LJyfqRtWrTVTMxksdLdrxXzRh1LWOvaEop8I5rMUJtWH0euw8F10qLJRcSDwgILDnuOSzBp-DYpQthYHUf8McN85L_g20le3or1-J9RiKi7ENsLS-orWqYfQTuexJRtsl7yaGvxmJuotBvPtYWkKsC_0jHURQAQKmyWXHkNHsWlo83MrZB5ruebfKGUh6eL5r7myfa37YnaQuK9s187AAwfI2T0sOrofFz09n3i7ghGNr7Nvz9UsU106DIopkNIomLnGR5mPmp4"
    static let splash = "https://lh3.googleusercontent.com/aida-public/AB6AXuBQrCeaZ5Ro2JELX-zigcCjfzFhR3OFukNu3hE-utl66zRhG33AC1v-64B9B705KeiK1REsL04jKvYBSK_V99O9pBmWxZRWYzewQAZ6Sgg8tdzo3lZPRqA3PhyrUfsQjLj3eXJvNL7FC8VAbCLKoNI9CGHz__YD2-GoGApPGxmqLd1Z8-0IcKbllXecqDzuP7Lu1me5w3Ob0aa8eKfERqH4hZhxaELz7ttPoVbLI4UTSdXQwb5L2ZAM216vYUAIOAF-Ms7qB8IcXVs"
    static let profile = "https://lh3.googleusercontent.com/aida-public/AB6AXuA-vbi1JIQfZw3urqGxpKdf2cOS3JEgdz6bTva2vzO3kozKBfffFN5Z1kv8k47mMGomgiS3-kCXdK0h7Vzrb2hKkas8oypDYbOts48AMVhJHepb0cEpseoZEIZOfVb8e1tLSVI_FKAutqOobUw-7THVEDRcZqUjyhf5qhzhtPQLA8bVNADspnaylzaUj_K0Y1GWL9-nalI7rI0peE0Ztp2UlZ76Lo31jUomLiPMCWCsPuoJZonOwQLj_R_0FYZzAnzNh6DLNz5QSgE"

    private static let figureImages = [
        "darth-vader-obiwan": "https://lh3.googleusercontent.com/aida-public/AB6AXuAyn-zxDdGAjf67cO97Ph8LRVBTiQNSiizK1UiuUA4gV02ImWIG1ihXlSwEYrgSQDTYkthJg_ix_CrDMmYqHITartIEmHqWmWtsQ4t5I6_fOeGhdyBD7WfZIKGBLe-re9h2nXQcXizqVGoCsC4fwUmNZSnr9dL8fWFOnD-294bBSq-sogDD_nHosCkUAlbQmHZQdEsH3UAY-uC8p1u-2APywOutSwNGNTR8Q1lgO7ucdHTbQMSaMpbfcXmAPtnTHeZzr_2EP7W7Ebo",
        "bo-katan-kryze": "https://lh3.googleusercontent.com/aida-public/AB6AXuD5-hc_JcybSIHdqrdaZbKy6eyjI0fldQNWjPb_gfnlJ9JTRFhosa1Oo4dg_bc3Xer9XKrkDKiwmy9OsubERkJnHe46I8V3h4qgjzV_gR2MR-wem1QQwXXKcdUEawEZTXyddlTPtP3lWBNFbn_G5gFT9pQvIlBTq-4mXeA_mjcduAB-MxKcGAFa1v7jFRZAjCvgHsR5UV3ufhdJFdQjDpPqLY7LTGe-IlCZMj4Hw7ij191E_iaLOj6V6Di_CKMTw0EQXEA8SD5nI_o",
        "captain-rex-clone-wars": "https://lh3.googleusercontent.com/aida-public/AB6AXuAtuTVT8ozgvcI_zN8vxvwDQQYw_5eegBZZpYpnDUmuZ-lM5BXAR1EcG8S0pbQw_-0KW2wuPqPdCv7HSpAi2SezZVluh6V9W8uAc7sUY3gohtv7QDjwptZYx8j-vg1au_zSv-wO8ilaUwIRgsPWDLNZBlvBUmkKsqrVF0Hzr9axACUC3qG9g22aRsm3FYDAG8iQs7dp0c1wwJJRapgaEycAcJbgjS52VLsP4In3h10t4SAn_6SZ7TO6xCFSYztYBPugktLHZ3orttI",
        "stormtrooper-jedha-patrol": "https://lh3.googleusercontent.com/aida-public/AB6AXuD01xgoEYXAI_k86zaRm8Vd86It-t-uZ-zR8ARY-9dJm-2RGQKHJskgNTZsYkn9lp9dW8Ej6j2Ve6T9AawPL30IP0FQO3h1HVHMmWPOPe2tWjZvDx1EACmRyjNGnxQWHx8kMlsUfFHQVKWBu07wi4aZ7zYN9LMZDwOYwiFgqHQdpd2br6jfIhl2RAMWMLOg_qDcgn5wXgimoya9r0gzB3Bot4HnDI5gkNfAWagLBLudJzJM_SsmIhxfkiXN-xHM7ALkThpPbZF6UpM",
        "boba-fett-tython": "https://lh3.googleusercontent.com/aida-public/AB6AXuD1ZO6hg07v7OdkC2rGoUgDMwzYufsqTN--Va3iltL5wv-uFjEjA_b5SK2j-dI8MftV-c0nUvbz2t-3IrU9qRnsdvLfjkvu7jaUVcdi1KtonI5aabOHmyT2AlbUeh_qcDPATTa1GWMCP4ZyHGvDJvkNu7_ptR1x0Y90-O3Y0RGdwN4I1ZdgL-P9NqQBCBP0fs2xhygA_8DpCfytxegQFgOb22kXuKBh5IbpTBcPr2BVNxN7Y0fAurxNFu4i0LTGg_cFkEMtTGH9gsA",
        "mando-ahsoka-tano": "https://lh3.googleusercontent.com/aida-public/AB6AXuBTwe-CKJsR7FjDV8g6QkU-RRc7jPJTas0ZMHOKBX-SsBYj62KWyNaHdaFIbVZ7vN_090NW7dioY38NNb0-OE1FTwLoH-4Xxc9LIOlAPiLOJu3E83NQjY3X2g91AsiISMrv0g_WgxTk63ST0GPgwHEOA2vCBt5pqy6LZiJAdM3nZiZmncNLHjM2qZN26iHoEUU0RAwexjJIvxLUaRZrsk0nz4a7x1vlbNUM2xARke3_a7T5QE3OloApxr7IAk05qF6F-pHSKZldzDY"
    ]

    static func heroImage(for figure: CatalogFigure) -> String {
        figureImages[figure.id] ?? figureImages.values.first ?? avatar
    }
}
