import SwiftUI

// Tab bar auto-hide: the reader-chrome pattern Apple News uses. The tab bar
// only shows at rest — scroll down into an article and it slides away;
// scroll back up (or stop near the top) and it returns. A floating glass
// toolbar (back + reactions + share + more) stays pinned the whole time,
// so it isn't tied to the tab bar's visibility at all.

struct TabBarAutoHideView: View {
    var body: some View {
        List {
            Section {
                Text("News hides its tab bar as you read, not on a timer or a single "
                     + "scroll-past-a-point rule, but on direction: scroll down and it "
                     + "slides away within a few points; scroll up — even briefly — and "
                     + "it's back. Near the very top it never leaves. The back/reaction/"
                     + "share/more cluster above it is a separate floating toolbar that "
                     + "doesn't hide at all, so there's always a way out and always a way "
                     + "to act on what you're reading.")
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
                Text("This hides the app's real tab bar and draws its own — scroll down, then back up.")
            }

            Section("How it's built") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("""
                    TabView {
                        Tab("Today", systemImage: "newspaper") { TodayFeed() }
                        ...
                    }
                    .tabBarMinimizeBehavior(.onScrollDown)
                    """)
                    .font(.mono(.caption))
                    .padding(8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text("That's the real, one-line API — it lives on the TabView itself, "
                         + "so it can't be demonstrated by pushing a nested one inside this "
                         + "catalog. The live demo above recreates the same feel by hand: it "
                         + "tracks scroll direction with onScrollGeometryChange and slides its "
                         + "own fake tab bar in and out to match.")
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
    @Environment(\.dismiss) private var dismiss
    @State private var barHidden = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Color.clear.frame(height: 56)
                Text("Trade tensions reach new levels")
                    .font(.title2.weight(.bold))
                ForEach(0..<18, id: \.self) { i in
                    paragraph(i)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .onScrollGeometryChange(for: CGFloat.self, of: { geo in
            geo.contentOffset.y + geo.contentInsets.top
        }, action: { old, new in
            let delta = new - old
            if new <= 4 {
                withAnimation(.snappy(duration: 0.28)) { barHidden = false }
            } else if delta > 4 {
                withAnimation(.snappy(duration: 0.28)) { barHidden = true }
            } else if delta < -4 {
                withAnimation(.snappy(duration: 0.28)) { barHidden = false }
            }
        })
        .safeAreaInset(edge: .bottom) {
            if !barHidden {
                tabBar
                    .padding(.bottom, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .top) {
            floatingToolbar.padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    private func paragraph(_ i: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Capsule().fill(Color(.systemFill)).frame(height: 8)
            Capsule().fill(Color(.systemFill)).frame(height: 8)
            Capsule().fill(Color(.quaternarySystemFill)).frame(width: 220, height: 8)
        }
        .padding(.top, i == 0 ? 4 : 0)
    }

    private var floatingToolbar: some View {
        GlassEffectContainer(spacing: 10) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                }
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 40, height: 40)
                .glassEffect(.regular, in: .circle)

                Spacer()

                HStack(spacing: 16) {
                    Image(systemName: "hand.thumbsup")
                    Image(systemName: "hand.thumbsdown")
                    Image(systemName: "square.and.arrow.up")
                    Image(systemName: "ellipsis")
                }
                .font(.system(size: 15, weight: .medium))
                .padding(.horizontal, 16)
                .frame(height: 40)
                .glassEffect(.regular, in: .capsule)
            }
        }
        .padding(.horizontal, 16)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(["newspaper.fill", "square.stack.fill", "headphones", "star.fill"], id: \.self) { s in
                Image(systemName: s).frame(maxWidth: .infinity)
            }
        }
        .font(.system(size: 17, weight: .medium))
        .frame(height: 48)
        .padding(.horizontal, 8)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 48)
    }
}

// MARK: - Reference data

private struct TabBarAutoHideRule: Identifiable {
    let id = UUID()
    let title: String
    let detail: String

    static let all: [TabBarAutoHideRule] = [
        TabBarAutoHideRule(title: "Hide on direction, not position", detail: "Trigger off scroll delta (down = hide, up = show), not a single fixed offset."),
        TabBarAutoHideRule(title: "Never hide near the top", detail: "Force the bar visible again below a small offset so it doesn't vanish on a page that barely scrolls."),
        TabBarAutoHideRule(title: "Keep exits and actions separate from the bar", detail: "A floating toolbar for back/share/more shouldn't hide with the tab bar — people need it whether or not they're mid-scroll."),
        TabBarAutoHideRule(title: "Animate both directions the same way", detail: "Use one snappy animation for hide and reveal so the motion reads as one continuous behavior, not two different ones."),
        TabBarAutoHideRule(title: "Use the system API when you can", detail: "`.tabBarMinimizeBehavior(.onScrollDown)` on the TabView gets you this for free — hand-roll it only when you need custom triggers."),
    ]
}

#Preview {
    NavigationStack {
        TabBarAutoHideView()
    }
}
