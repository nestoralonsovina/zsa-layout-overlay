import SwiftUI

enum PrefsTab: String, CaseIterable {
    case general = "General"
    case appearance = "Appearance"
    case layout = "Layout"

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintpalette"
        case .layout: "keyboard"
        }
    }
}

struct PreferencesView: View {
    @Bindable private var prefs = PreferencesStore.shared
    @State private var selectedTab = PrefsTab.general

    var body: some View {
        VStack(spacing: 0) {
            tabPicker

            Divider()
                .padding(.horizontal)

            tabContent
                .padding(20)
        }
        .frame(minWidth: 440, minHeight: 440)
        .background(WindowBackground())
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(PrefsTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .medium))
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .contentShape(RoundedRectangle(cornerRadius: 7))
                .buttonStyle(.plain)
                .foregroundStyle(selectedTab == tab ? Color.accentColor : .secondary)
                .background {
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.accentColor.opacity(0.12))
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.06))
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .general:
            GeneralTab(prefs: prefs)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .leading)),
                    removal: .opacity.combined(with: .move(edge: .trailing))
                ))
        case .appearance:
            AppearanceTab(prefs: prefs)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: selectedTab == .appearance ? .leading : .trailing)),
                    removal: .opacity.combined(with: .move(edge: .trailing))
                ))
        case .layout:
            LayoutTab(prefs: prefs)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
        }
    }
}

// MARK: - General Tab

private struct GeneralTab: View {
    @Bindable var prefs: PreferencesStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CardSection(
                    icon: "macwindow.on.rectangle",
                    title: "Window Behavior"
                ) {
                    ToggleRow(
                        icon: "rectangle.on.rectangle",
                        label: "Follow focused screen",
                        detail: "Overlay moves to the active display",
                        isOn: $prefs.followFocusedScreen
                    )
                }

                CardSection(
                    icon: "arrow.left.and.right",
                    title: "Position"
                ) {
                    VStack(spacing: 10) {
                        ValueSliderRow(
                            icon: "arrow.left.and.right",
                            label: "Horizontal",
                            value: $prefs.positionX,
                            range: 0...1,
                            step: 0.01,
                            format: { String(format: "%d%%", Int($0 * 100)) }
                        )

                        ValueSliderRow(
                            icon: "arrow.up.and.down",
                            label: "Vertical",
                            value: $prefs.positionY,
                            range: 0...1,
                            step: 0.01,
                            format: { String(format: "%d%%", Int($0 * 100)) }
                        )
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                        Text("0% = bottom, 100% = top")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }

                CardSection(
                    icon: "arrow.up.left.and.down.right.magnifyingglass",
                    title: "Size"
                ) {
                    ValueSliderRow(
                        icon: "arrow.up.left.and.down.right.magnifyingglass",
                        label: "Scale",
                        value: $prefs.scaleMultiplier,
                        range: 0.5...1.5,
                        step: 0.05,
                        format: { String(format: "%.0f%%", $0 * 100) }
                    )
                }
            }
        }
    }
}

// MARK: - Appearance Tab

private struct AppearanceTab: View {
    @Bindable var prefs: PreferencesStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CardSection(
                    icon: "circle.lefthalf.filled",
                    title: "Opacity"
                ) {
                    VStack(spacing: 10) {
                        ValueSliderRow(
                            icon: "rectangle.on.rectangle",
                            label: "Overlay",
                            value: $prefs.overlayOpacity,
                            range: 0.2...1.0,
                            step: 0.05,
                            format: { String(format: "%.0f%%", $0 * 100) }
                        )

                        ValueSliderRow(
                            icon: "keyboard",
                            label: "Keycaps",
                            value: $prefs.keycapOpacity,
                            range: 0.2...1.0,
                            step: 0.05,
                            format: { String(format: "%.0f%%", $0 * 100) }
                        )
                    }
                }

                CardSection(
                    icon: "timer",
                    title: "Fade Behavior"
                ) {
                    ValueSliderRow(
                        icon: "timer",
                        label: "Delay",
                        value: $prefs.chromeFadeDelay,
                        range: 0.5...6.0,
                        step: 0.5,
                        format: { String(format: "%.1fs", $0) }
                    )
                }
            }
        }
    }
}

// MARK: - Layout Tab

private struct LayoutTab: View {
    @Bindable var prefs: PreferencesStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CardSection(
                    icon: "link",
                    title: "Layout Source"
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter your Oryx share URL or layout hash:")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        TextField("https://configure.zsa.io/voyager/layouts/LmpYy/latest", text: Binding(
                            get: { prefs.layoutURL ?? "" },
                            set: { prefs.layoutURL = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11))
                        .controlSize(.small)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                        Text("Open your layout on oryx.zsa.io, click Share, and copy the link. Changes trigger a reload.")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }

                CardSection(
                    icon: "arrow.counterclockwise",
                    title: "Reset"
                ) {
                    HStack {
                        Text("Restore all preferences to their defaults.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Reset to Defaults") {
                            prefs.resetToDefaults()
                        }
                        .controlSize(.small)
                    }
                }
            }
        }
    }
}

// MARK: - Shared Components

private struct CardSection<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            content
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.04))
                }
        }
    }
}

private struct ValueSliderRow: View {
    let icon: String
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .frame(width: 14)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 56, alignment: .leading)

            Slider(value: $value, in: range, step: step)
                .controlSize(.small)

            Text(format(value))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(valueLabelColor)
                .frame(width: 40, alignment: .trailing)
        }
    }

    private var valueLabelColor: Color {
        if range.contains(value) {
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            if fraction < 0.3 { return .orange }
            if fraction > 0.7 { return .accentColor }
            return .secondary
        }
        return .secondary
    }
}

private struct ToggleRow: View {
    let icon: String
    let label: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .frame(width: 14)

                Text(label)
                    .font(.system(size: 12))

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            Text(detail)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .padding(.leading, 24)
        }
    }
}

// MARK: - Window Background

private struct WindowBackground: View {
    var body: some View {
        ZStack {
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
        }
    }
}

private struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
