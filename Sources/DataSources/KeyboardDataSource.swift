import Foundation

enum ErrorState: Identifiable {
    case none
    case warning(String)
    case error(String)

    var id: String {
        switch self {
        case .none: return "none"
        case .warning(let msg): return "warning-\(msg.hashValue)"
        case .error(let msg): return "error-\(msg.hashValue)"
        }
    }

    var message: String {
        switch self {
        case .none: return ""
        case .warning(let msg), .error(let msg): return msg
        }
    }

    var isActive: Bool {
        if case .none = self { return false }
        return true
    }
}

@MainActor
protocol KeyboardDataSource {
    var onError: ((ErrorState) -> Void)? { get set }
    func start(feeding model: OverlayViewModel) async
}

struct KeyboardLiveState {
    let sourceName: String
    let connectionState: String
    let activeLayerIndex: Int?
    let pressedKeyIndices: Set<Int>
    let statusText: String?
}
