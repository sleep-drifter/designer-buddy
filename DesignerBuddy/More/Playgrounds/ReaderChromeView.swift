import SwiftUI

// Reader chrome, tuned by hand. A real scroll view drives two independent
// pieces of glass: a bottom tab bar that hides on downward scroll and
// returns on upward scroll (or near the top), and a floating top toolbar
// that never hides at all. Scroll the stage's list and watch the bar react
// to direction, not position — then bend its thresholds and spring.

struct ReaderChromeView: View {
    @State private var scrollY: Double = 0
    @State private var barHidden = false

    @State private var hideDelta: Double = 6
    @State private var showDelta: Double = 6
    @State private var topGuard: Double = 40
    @State private var response: Double = 0.32
    @State private var damping: Double = 0.86
    @State private var tinted = false

    private var spring: Animation { .spring(response: response, dampingFraction: damping) }
    private var chromeGlass: Glass { tinted ? .regular.tint(.red.opacity(0.5)) : .regular }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                controls
                caption
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .pinnedPreview(entry: "Reader Chrome") {
            stage
        }
        .navigationTitle("Reader Chrome")
    }

    // MARK: - Stage

    private var stage: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Color.clear.frame(height: 54)
                    ForEach(0..<20, id: \.self) { i in fakeParagraph(i) }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .onScrollGeometryChange(for: Double.self, of: { geo in
                Double(geo.contentOffset.y + geo.contentInsets.top)
            }, action: { _, new in
                let delta = new - scrollY
                scrollY = new
                if new <= topGuard {
                    if barHidden { withAnimation(spring) { barHidden = false } }
                } else if delta > hideDelta {
                    if !barHidden { withAnimation(spring) { barHidden = true } }
                } else if delta < -showDelta {
                    if barHidden { withAnimation(spring) { barHidden = false } }
                }
            })

            if !barHidden {
                tabBarMock
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            VStack {
                floatingToolbarMock.padding(.top, 8)
                Spacer()
            }
        }
        .frame(height: 260)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color(.separator), lineWidth: 0.5)
        )
    }

    private func fakeParagraph(_ i: Int) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Capsule().fill(Color(.systemFill)).frame(height: 7)
            Capsule().fill(Color(.systemFill)).frame(height: 7)
            Capsule().fill(Color(.quaternarySystemFill)).frame(width: 160, height: 7)
        }
    }

    private var floatingToolbarMock: some View {
        GlassEffectContainer(spacing: 10) {
            HStack {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .glassEffect(chromeGlass, in: .circle)
                Spacer()
                HStack(spacing: 14) {
                    Image(systemName: "hand.thumbsup")
                    Image(systemName: "hand.thumbsdown")
                    Image(systemName: "square.and.arrow.up")
                    Image(systemName: "ellipsis")
                }
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 14)
                .frame(height: 34)
                .glassEffect(chromeGlass, in: .capsule)
            }
        }
        .padding(.horizontal, 14)
    }

    private var tabBarMock: some View {
        HStack(spacing: 0) {
            ForEach(["newspaper.fill", "square.stack.fill", "headphones", "star.fill"], id: \.self) { s in
                Image(systemName: s).frame(maxWidth: .infinity)
            }
        }
        .font(.system(size: 15, weight: .medium))
        .frame(height: 42)
        .padding(.horizontal, 6)
        .glassEffect(chromeGlass, in: .capsule)
        .padding(.horizontal, 40)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 0) {
            sliderRow("Hide Delta", $hideDelta, 2...30, text: "\(Int(hideDelta))")
            divider
            sliderRow("Show Delta", $showDelta, 2...30, text: "\(Int(showDelta))")
            divider
            sliderRow("Top Guard", $topGuard, 0...120, text: "\(Int(topGuard))")
            divider
            sliderRow("Response", $response, 0.15...0.6, text: String(format: "%.2f", response))
            divider
            sliderRow("Damping", $damping, 0.5...1, text: String(format: "%.2f", damping))
            divider
            row { Toggle("Tint Glass", isOn: $tinted) }
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var caption: some View {
        Text("Every downward flick past Hide Delta points slides the tab bar away; "
             + "any upward scroll past Show Delta brings it back, and dropping below "
             + "Top Guard always forces it visible. The floating toolbar up top never "
             + "reacts to any of this — it's a separate piece of glass with its own "
             + "lifetime. Scroll the list above by hand to feel the difference, or drag "
             + "the deltas to make the bar twitchier or steadier.")
            .font(.footnote).foregroundStyle(.secondary)
            .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Row helpers

    private func sliderRow(_ label: String, _ value: Binding<Double>,
                           _ range: ClosedRange<Double>, text: String) -> some View {
        row {
            HStack(spacing: 12) {
                Text(label).frame(width: 96, alignment: .leading)
                Slider(value: value, in: range)
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
    NavigationStack { ReaderChromeView() }
        .environmentObject(PinsStore())
}
