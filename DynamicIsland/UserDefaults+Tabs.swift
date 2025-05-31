import Foundation

extension UserDefaults {
    private enum Keys {
        static let lastSelectedTab = "lastSelectedTab"
        static let enabledTabs = "enabledTabs"
    }
    
    var lastSelectedTab: MainViewType {
        get {
            if let rawValue = string(forKey: Keys.lastSelectedTab),
               let mainViewType = MainViewType(rawValue: rawValue) {
                return mainViewType
            }
            return .clipboard // default
        }
        set {
            set(newValue.rawValue, forKey: Keys.lastSelectedTab)
        }
    }
    
    var enabledTabs: Set<MainViewType> {
        get {
            if let rawValues = array(forKey: Keys.enabledTabs) as? [String] {
                let enabledTypes = rawValues.compactMap { MainViewType(rawValue: $0) }
                return Set(enabledTypes)
            }
            // Default: all tabs enabled
            return Set([.clipboard, .quickApp, .systemMonitor, .weather, .timer])
        }
        set {
            let rawValues = newValue.map { $0.rawValue }
            set(rawValues, forKey: Keys.enabledTabs)
        }
    }
}

extension MainViewType: RawRepresentable {
    public var rawValue: String {
        switch self {
        case .clipboard: return "clipboard"
        case .quickApp: return "quickApp"
        case .systemMonitor: return "systemMonitor"
        case .weather: return "weather"
        case .timer: return "timer"
        }
    }
    
    public init?(rawValue: String) {
        switch rawValue {
        case "clipboard": self = .clipboard
        case "quickApp": self = .quickApp
        case "systemMonitor": self = .systemMonitor
        case "weather": self = .weather
        case "timer": self = .timer
        default: return nil
        }
    }
} 