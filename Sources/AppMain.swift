import AppKit

@main
enum AppMain {
    static func main() {
        AppFonts.registerBundledFonts()

        if CommandLine.arguments.contains("--check-har") {
            let harPath = CommandLine.arguments.dropFirst().first(where: { $0 != "--check-har" })
                ?? "/Users/nestoralonsovina/Downloads/typ.ing.har"
            do {
                let capture = try OryxHARLoader.load(from: harPath)
                print("Loaded layout \(capture.layoutID) revision \(capture.revisionID) geometry \(capture.geometry)")
                print("Layers (\(capture.layers.count)):")
                for layer in capture.layers {
                    print("- [\(layer.index)] \(layer.title) keys=\(layer.keys.count)")
                }
                exit(0)
            } catch {
                fputs("HAR parse failed: \(OryxHARDataSource(harPath: harPath).debugDescription(for: error))\n", stderr)
                exit(1)
            }
        }

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
