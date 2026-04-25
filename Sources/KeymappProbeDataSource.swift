import Foundation
@MainActor
struct KeymappProbeDataSource: KeyboardDataSource {
    func start(feeding model: OverlayViewModel) async {
        let probe = KeymappSocketProbe()
        let result = await probe.probe()

        let statusText: String
        let state: String

        switch result {
        case .present(let path):
            state = "socket detected"
            statusText = "Keymapp socket exists at \(path). The next step is to add a generated gRPC client for the real API."
        case .missing(let searchedPaths):
            state = "socket missing"
            statusText = "No Keymapp socket found. Searched: \(searchedPaths.joined(separator: ", "))"
        }

        model.applyStatus(sourceName: "keymapp-probe", connectionState: state, statusText: statusText)
    }
}

struct KeymappSocketProbe {
    enum Result {
        case present(path: String)
        case missing(searchedPaths: [String])
    }

    func probe() async -> Result {
        let paths = candidatePaths()

        for path in paths {
            guard socketExists(atPath: path) else {
                continue
            }

            return .present(path: path)
        }

        return .missing(searchedPaths: paths)
    }

    private func candidatePaths() -> [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let configHome = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] ?? "\(home)/.config"
        return [
            "\(configHome)/.keymapp/keymapp.sock",
            "\(home)/Library/Application Support/.keymapp/keymapp.sock"
        ]
    }

    private func socketExists(atPath path: String) -> Bool {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            if let type = attributes[.type] as? FileAttributeType {
                return type == .typeSocket || type == .typeUnknown
            }
            return true
        } catch {
            return false
        }
    }
}
