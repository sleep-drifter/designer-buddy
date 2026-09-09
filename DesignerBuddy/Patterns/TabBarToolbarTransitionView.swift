import SwiftUI

// Tab bar → toolbar: the transition system apps use when a screen enters a
// selection or edit flow. The TabView's own tab bar hides and a contextual
// `.bottomBar` toolbar takes its place, so the chrome you land on always
// matches the actions available right now — Cancel/Done up top, Delete/
// Move/Share where the tab icons used to be.

struct TabBarToolbarTransitionView: View {
    var body: some View {
        List {
            Section {
                Text("Photos, Files, Notes, and Mail all do this: tap Select and the "
                     + "tab bar at the bottom is replaced by a toolbar of actions that "
                     + "only make sense once something is selected. It reads as one "
                     + "continuous piece of chrome because both bars occupy the exact "
                     + "same strip — the system swaps what's inside it, not where it sits.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            Section {
                NavigationLink("Selectable Library") {
                    SelectionToolbarDemo()
                }
            } header: {
                Text("Live Demo")
            } footer: {
                Text("This hides the app's real tab bar — tap Select to watch it happen, then Done to bring it back.")
            }

            Section("How it's built") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("""
                    @State private var isSelecting = false

                    .toolbar(isSelecting ? .hidden : .visible, for: .tabBar)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(isSelecting ? "Done" : "Select") {
                                withAnimation(.snappy) { isSelecting.toggle() }
                            }
                        }
                        if isSelecting {
                            ToolbarItemGroup(placement: .bottomBar) {
                                Button("Delete", role: .destructive) { }
                                Spacer()
                                Button("Move") { }
                                Spacer()
                                Button("Share") { }
                            }
                        }
                    }
                    """)
                    .font(.mono(.caption))
                    .padding(8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text("Text-only buttons work fine here — the role: .destructive on "
                         + "Delete gets its red tint for free, no icon required. Wrap the "
                         + "state change in withAnimation and the system animates both "
                         + "halves together: the tab bar slides out as the toolbar's "
                         + "buttons fade in.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Where it shows up") {
                ForEach(TabToolbarExample.all) { example in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(example.app).font(.subheadline).fontWeight(.medium)
                        Text(example.detail).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("Rules") {
                ForEach(TabToolbarRule.all) { rule in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rule.title).font(.subheadline).fontWeight(.medium)
                        Text(rule.detail).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Tab Bar → Toolbar")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Live demo

private struct SelectionToolbarDemo: View {
    @State private var isSelecting = false
    @State private var selected: Set<Int> = []

    private let items: [(name: String, icon: String)] = [
        ("Sunset Drive", "photo"), ("Campfire Loop", "photo"),
        ("Harbor Lights", "photo"), ("Nightfall", "photo"),
        ("Skyline Run", "photo"), ("Tidepool", "photo"),
        ("Ridge Trail", "photo"), ("Low Tide", "photo"),
    ]

    var body: some View {
        List(selection: $selected) {
            ForEach(items.indices, id: \.self) { i in
                row(i).tag(i)
            }
        }
        .environment(\.editMode, .constant(isSelecting ? .active : .inactive))
        .navigationTitle(isSelecting
                         ? (selected.isEmpty ? "Select Items" : "\(selected.count) Selected")
                         : "Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(isSelecting ? .hidden : .visible, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isSelecting ? "Done" : "Select") {
                    withAnimation(.snappy(duration: 0.32)) {
                        isSelecting.toggle()
                        if !isSelecting { selected.removeAll() }
                    }
                }
            }
            if isSelecting {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Delete", role: .destructive) { selected.removeAll() }
                        .disabled(selected.isEmpty)
                    Spacer()
                    Button("Move") { }
                        .disabled(selected.isEmpty)
                    Spacer()
                    Button("Share") { }
                        .disabled(selected.isEmpty)
                }
            }
        }
    }

    private func row(_ i: Int) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.quaternary)
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: items[i].icon).foregroundStyle(.secondary))
            Text(items[i].name)
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Reference data

private struct TabToolbarExample: Identifiable {
    let id = UUID()
    let app: String
    let detail: String

    static let all: [TabToolbarExample] = [
        TabToolbarExample(app: "Photos", detail: "Select turns the tab bar into Share / Delete / Add-to-album."),
        TabToolbarExample(app: "Files", detail: "Select swaps browsing tabs for Move / Duplicate / Delete / Share."),
        TabToolbarExample(app: "Notes", detail: "Select on a folder list shows Move / Share / Delete for notes."),
        TabToolbarExample(app: "Mail", detail: "Edit on a mailbox list shows Mark / Move / Trash / More."),
    ]
}

private struct TabToolbarRule: Identifiable {
    let id = UUID()
    let title: String
    let detail: String

    static let all: [TabToolbarRule] = [
        TabToolbarRule(title: "Only during a transient flow", detail: "Selection/edit mode is temporary — always give an obvious way back out (Done or Cancel)."),
        TabToolbarRule(title: "Match the actions to the selection", detail: "Disable actions that don't apply until at least one item is selected."),
        TabToolbarRule(title: "Animate the swap, don't cut it", detail: "Wrap the state change in withAnimation so the bars cross-fade instead of popping."),
        TabToolbarRule(title: "Keep the title in sync", detail: "Show a count (\"3 Selected\") instead of the screen's normal title while selecting."),
        TabToolbarRule(title: "Don't hide navigation the user needs", detail: "If people still need to switch tabs mid-flow, this pattern isn't the right fit."),
    ]
}

#Preview {
    NavigationStack {
        TabBarToolbarTransitionView()
    }
}
