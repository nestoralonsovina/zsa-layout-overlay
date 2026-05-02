import SwiftUI
import AppKit

@MainActor
final class PreferencesWindowController {
    private var window: NSWindow?

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = PreferencesView()
        let hostingView = NSHostingView(rootView: view)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct PreferencesView: View {
    @StateObject private var prefs = PreferencesStore.shared

    var body: some View {
        Form {
            Section {
                Toggle("Follow focused screen", isOn: $prefs.followFocusedScreen)
            }

            Section("Position") {
                HStack {
                    Text("X")
                        .frame(width: 20, alignment: .leading)
                    Slider(value: $prefs.positionX, in: 0...1, step: 0.01)
                    Text(String(format: "%d%%", Int(prefs.positionX * 100)))
                        .monospacedDigit()
                        .frame(width: 38, alignment: .trailing)
                }

                HStack {
                    Text("Y")
                        .frame(width: 20, alignment: .leading)
                    Slider(value: $prefs.positionY, in: 0...1, step: 0.01)
                    Text(String(format: "%d%%", Int(prefs.positionY * 100)))
                        .monospacedDigit()
                        .frame(width: 38, alignment: .trailing)
                }

                Text("0% Y = bottom edge, 100% Y = top edge")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Size") {
                HStack {
                    Text("Scale")
                    Slider(value: $prefs.scaleMultiplier, in: 0.5...1.5, step: 0.05)
                    Text(String(format: "%.0f%%", prefs.scaleMultiplier * 100))
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                }
            }

            Section("Appearance") {
                HStack {
                    Text("Overlay")
                    Slider(value: $prefs.overlayOpacity, in: 0.2...1.0, step: 0.05)
                    Text(String(format: "%.0f%%", prefs.overlayOpacity * 100))
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                }

                HStack {
                    Text("Keys")
                    Slider(value: $prefs.keycapOpacity, in: 0.2...1.0, step: 0.05)
                    Text(String(format: "%.0f%%", prefs.keycapOpacity * 100))
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                }

                HStack {
                    Text("Fade")
                    Slider(value: $prefs.chromeFadeDelay, in: 0.5...6.0, step: 0.5)
                    Text(String(format: "%.1fs", prefs.chromeFadeDelay))
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                }
            }

            Section("Layout") {
                HStack {
                    Text("HAR File")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let path = prefs.harFilePath {
                        Text((path as NSString).lastPathComponent)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not set")
                            .foregroundStyle(.secondary)
                    }
                    Button("Choose...") {
                        chooseHARFile()
                    }
                    .controlSize(.small)
                }
            }

            HStack {
                Spacer()
                Button("Reset to Defaults") {
                    prefs.resetToDefaults()
                }
                .controlSize(.small)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(minWidth: 400, minHeight: 360)
    }

    private func chooseHARFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.init(filenameExtension: "har")!]

        panel.begin { result in
            if result == .OK, let url = panel.url {
                PreferencesStore.shared.harFilePath = url.path
            }
        }
    }
}
