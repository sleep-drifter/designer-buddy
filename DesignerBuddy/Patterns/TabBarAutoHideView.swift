import SwiftUI

// Tab bar auto-hide: the reader-chrome pattern Apple News uses. The tab bar
// only shows at rest — scroll down into an article and it slides away;
// scroll back up (or stop near the top) and it returns. None of that is
// custom: it's one modifier on a real TabView. The reaction/share/more
// toolbar above the content is a completely separate, always-visible piece
// of chrome that isn't tied to the tab bar's visibility at all.

struct TabBarAutoHideView: View {
    var body: some View {
        List {
            Section {
                Text("News hides its tab bar as you read: scroll down and it slides "
                     + "away within a few points; scroll up — even briefly — and it's "
                     + "back. Near the very top it never leaves. That's system behavior, "
                     + "not a hand-rolled scroll listener — one modifier on a plain "
                     + "TabView with ordinary tabs, no dedicated search tab required. "
                     + "The reaction/share/more toolbar above the article doesn't hide "
                     + "with it, so there's always a way to act on what you're reading.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            Section {
                NavigationLink("Article Reader") {
                    TabBarAutoHideDemo()
                }
            } header: {
                Text("Live Demo")
            } footer: {
                Text("A real TabView with three plain tabs — open the article, scroll down, then back up.")
            }

            Section("How it's built") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("""
                    TabView {
                        Tab("Today", systemImage: "newspaper") { TodayFeed() }
                        Tab("Following", systemImage: "star") { FollowingFeed() }
                        Tab("Audio", systemImage: "headphones") { AudioFeed() }
                    }
                    .tabBarMinimizeBehavior(.onScrollDown)
                    """)
                    .font(.mono(.caption))
                    .padding(8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text("That's the whole thing — no scroll tracking, no manual "
                         + "animation, and no role: .search tab, which is what would "
                         + "detach a search icon into its own floating pill next to the "
                         + "bar. Inside a tab's own NavigationStack, an ordinary trailing "
                         + "ToolbarItemGroup gets the glass-pill treatment for free and "
                         + "is completely unaffected by tabBarMinimizeBehavior.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Rules") {
                ForEach(TabBarAutoHideRule.all) { rule in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rule.title).font(.subheadline).fontWeight(.medium)
                        Text(rule.detail).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Tab Bar Auto-Hide")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Live demo

private struct TabBarAutoHideDemo: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "newspaper") {
                NavigationStack {
                    TodayFeedDemo()
                }
            }
            Tab("Following", systemImage: "star") {
                NavigationStack {
                    Text("Following").foregroundStyle(.secondary)
                        .navigationTitle("Following")
                }
            }
            Tab("Audio", systemImage: "headphones") {
                NavigationStack {
                    Text("Audio").foregroundStyle(.secondary)
                        .navigationTitle("Audio")
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

private struct TodayFeedDemo: View {
    private let headlines = [
        "Markets steady after morning selloff",
        "What the new tariffs mean for shipping",
        "Five charts on the trade standoff",
        "Ports brace for a slower fourth quarter",
    ]

    var body: some View {
        List {
            NavigationLink("Trade tensions reach new levels") {
                ArticleReaderDemo()
            }
            ForEach(headlines, id: \.self) { headline in
                Text(headline)
            }
        }
        .navigationTitle("Today")
    }
}

private struct ArticleReaderDemo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero
                VStack(alignment: .leading, spacing: 16) {
                    Text("Trade tensions reach new levels")
                        .font(.title2.weight(.bold))
                    ForEach(0..<14, id: \.self) { i in paragraph(i) }
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { } label: {
                    Image(systemName: "hand.thumbsup")
                }
                Button { } label: {
                    Image(systemName: "hand.thumbsdown")
                }
                ShareLink(item: URL(string: "https://example.com")!)
                Menu("More") {
                    Button("Save Article", systemImage: "bookmark") { }
                    Button("Text Size", systemImage: "textformat.size") { }
                    Button("Report a Problem", systemImage: "flag") { }
                }
            }
        }
    }

    private var hero: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.6), Color.accentColor.opacity(0.15)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 220)
            .ignoresSafeArea(edges: .top)
    }

    private func paragraph(_ i: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Capsule().fill(Color(.systemFill)).frame(height: 8)
            Capsule().fill(Color(.systemFill)).frame(height: 8)
            Capsule().fill(Color(.quaternarySystemFill)).frame(width: 220, height: 8)
        }
    }
}

// MARK: - Reference data

private struct TabBarAutoHideRule: Identifiable {
    let id = UUID()
    let title: String
    let detail: String

    static let all: [TabBarAutoHideRule] = [
        TabBarAutoHideRule(title: "Reach for tabBarMinimizeBehavior first", detail: "It's one modifier on the TabView — hand-roll scroll tracking only for triggers the system behavior can't express."),
        TabBarAutoHideRule(title: "Only add a search role if you have one", detail: "Marking a tab role: .search detaches it into its own floating pill next to the main bar — skip it if your app doesn't have a dedicated search tab."),
        TabBarAutoHideRule(title: "Keep exits and actions separate from the bar", detail: "A toolbar for reactions/share/more shouldn't hide with the tab bar — people need it whether or not they're mid-scroll."),
        TabBarAutoHideRule(title: "Let adjacent toolbar buttons merge on their own", detail: "Group related actions in one ToolbarItemGroup and the glass pill forms automatically — no GlassEffectContainer needed for ordinary toolbar content."),
        TabBarAutoHideRule(title: "Prefer .never over fighting the default", detail: "If a screen shouldn't minimize, set tabBarMinimizeBehavior(.never) rather than hiding it yourself with custom state."),
    ]
}

#Preview {
    NavigationStack {
        TabBarAutoHideView()
    }
}
