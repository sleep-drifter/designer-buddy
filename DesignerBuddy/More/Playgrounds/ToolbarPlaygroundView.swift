import SwiftUI

// Tab bar → toolbar, scrubbed by hand. The real transition swaps a TabView's
// own tab bar for a `.bottomBar` toolbar of contextual actions — see the
// Tab Bar → Toolbar pattern page for that live, Select-button-driven version.
// Here the swap is driven by a manual progress value instead, so it can be
// held open at any point between the two chromes rather than only snapping
// between endpoints.

struct ToolbarPlaygroundView: View {
    @State private var progress: Double = 0

    @State private var selectedCount: Double = 2
    @State private var response: Double = 0.4
    @State private var damping: Double = 0.8
    @State private var style: MorphStyle = .crossFade
    @State private var tinted = false

    private enum MorphStyle: String, CaseIterable, Identifiable {
        case crossFade = "Cross-fade", slideUp = "Slide Up"
        var id: String { rawValue }
    }

    private var spring: Animation { .spring(response: response, dampingFraction: damping) }
    private var selecting: Bool { progress > 0.5 }
    private var chromeGlass: Glass { tinted ? .regular.tint(.orange.opacity(0.5)) : .regular }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                controls
                caption
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .pinnedPreview(entry: "Toolbar Playground") {
            stage
        }
        .navigationTitle("Toolbar Playground")
    }

    // MARK: - Stage

    // The list fills the whole stage and both chrome pieces float on top of
    // it, exactly like ToolbarCondenseView/TabBarMiniPlayerView — the glass
    // needs real content scrolling underneath it to actually blur, or it
    // just renders as a flat tinted shape with nothing behind it.
    private var stage: some View {
        ScrollView {
            VStack(spacing: 10) {
                Color.clear.frame(height: 52)
                ForEach(0..<10, id: \.self) { i in fakeRow(i) }
                Color.clear.frame(height: 70)
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 300)
        .background(Color(.systemBackground))
        .overlay(alignment: .top) {
            titleBar.padding(.horizontal, 12).padding(.top, 10)
        }
        .overlay(alignment: .bottom) {
            chromeBar
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color(.separator), lineWidth: 0.5)
        )
    }

    private var titleBar: some View {
        HStack {
            Text(selecting ? "\(Int(selectedCount)) Selected" : "Library")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button(selecting ? "Done" : "Select") {
                snap(to: selecting ? 0 : 1)
            }
            .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .frame(height: 40)
        .glassEffect(chromeGlass, in: .capsule)
        .animation(spring, value: selecting)
    }

    private func fakeRow(_ i: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: i < Int(selectedCount) ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(i < Int(selectedCount) ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                .opacity(progress)
                .frame(width: 22)
            Circle().fill(Color(.systemFill)).frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 5) {
                Capsule().fill(Color(.systemFill)).frame(width: 120, height: 8)
                Capsule().fill(Color(.quaternarySystemFill)).frame(width: 80, height: 8)
            }
            Spacer()
        }
        .padding(10)
        .background(Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // Only the tab bar floats as an inset capsule (the real iOS 26 tab bar
    // shape) — a real .bottomBar toolbar is a full-width bar flush to the
    // bottom edge, not another floating pill, so the two don't share a shape.
    private var chromeBar: some View {
        ZStack(alignment: .bottom) {
            tabBarMock
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
                .opacity(1 - progress)
                .offset(y: style == .slideUp ? 20 * progress : 0)
            toolbarMock
                .opacity(progress)
                .offset(y: style == .slideUp ? 20 * (1 - progress) : 0)
        }
        .frame(height: 74)
    }

    private var tabBarMock: some View {
        HStack {
            ForEach(["house.fill", "magnifyingglass", "photo.stack", "person.fill"], id: \.self) { s in
                Image(systemName: s).frame(maxWidth: .infinity)
            }
        }
        .font(.system(size: 16, weight: .medium))
        .frame(height: 44)
        .glassEffect(chromeGlass, in: .capsule)
    }

    private var toolbarMock: some View {
        HStack {
            Spacer()
            Image(systemName: "trash")
            Spacer()
            Image(systemName: "folder")
            Spacer()
            Image(systemName: "square.and.arrow.up")
            Spacer()
        }
        .font(.system(size: 17, weight: .medium))
        .frame(height: 54)
        .frame(maxWidth: .infinity)
        .glassEffect(chromeGlass, in: .rect(cornerRadius: 0))
        .overlay(alignment: .top) { Divider() }
    }

    // MARK: - Controls

    private func snap(to value: Double) {
        withAnimation(spring) { progress = value }
    }

    private var controls: some View {
        VStack(spacing: 0) {
            scrubRow
            divider
            sliderRow("Selected", $selectedCount, 1...6, step: 1, text: "\(Int(selectedCount))")
            divider
            sliderRow("Response", $response, 0.15...0.8, text: String(format: "%.2f", response))
            divider
            sliderRow("Damping", $damping, 0.5...1, text: String(format: "%.2f", damping))
            divider
            row {
                HStack {
                    Text("Style").frame(width: 96, alignment: .leading)
                    Spacer()
                    Picker("Style", selection: $style) {
                        ForEach(MorphStyle.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).frame(width: 210)
                }
            }
            divider
            row { Toggle("Tint Glass", isOn: $tinted) }
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var scrubRow: some View {
        row {
            HStack(spacing: 12) {
                Text("Scrub").frame(width: 96, alignment: .leading)
                Slider(value: $progress, in: 0...1) { editing in
                    if !editing { snap(to: progress.rounded()) }
                }
                Text(String(format: "%.2f", progress))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary).frame(width: 48, alignment: .trailing)
            }
        }
    }

    private var caption: some View {
        Text("The real version hides a TabView's tab bar with "
             + "`.toolbar(.hidden, for: .tabBar)` and shows a `.bottomBar` "
             + "ToolbarItemGroup in its place — the Tab Bar → Toolbar pattern page "
             + "has that live, wired to an actual Select button. Here the swap is "
             + "scrubbable: drag Scrub to hold the cross-fade or slide-up open at any "
             + "point, or tap Select/Done to watch Response and Damping shape the "
             + "spring that drives it.")
            .font(.footnote).foregroundStyle(.secondary)
            .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Row helpers

    private func sliderRow(_ label: String, _ value: Binding<Double>,
                           _ range: ClosedRange<Double>, step: Double = 0, text: String) -> some View {
        row {
            HStack(spacing: 12) {
                Text(label).frame(width: 96, alignment: .leading)
                if step > 0 {
                    Slider(value: value, in: range, step: step)
                } else {
                    Slider(value: value, in: range)
                }
                Text(text).font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary).frame(width: 48, alignment: .trailing)
            }
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content().padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View { Divider().padding(.leading, 16) }
}

// MARK: - Preview

#Preview {
    NavigationStack { ToolbarPlaygroundView() }
        .environmentObject(PinsStore())
}
