import Foundation

extension UserDefaults {
    private enum Keys {
        static let lastSelectedTab = "lastSelectedTab"
    }
    
    var lastSelectedTab: MainViewType {
        get {
            let rawValue = string(forKey: Keys.lastSelectedTab) ?? MainViewType.clipboard.rawValue
            return MainViewType(rawValue: rawValue) ?? .clipboard
        }
        set {
            set(newValue.rawValue, forKey: Keys.lastSelectedTab)
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
        }
    }
    
    public init?(rawValue: String) {
        switch rawValue {
        case "clipboard": self = .clipboard
        case "quickApp": self = .quickApp
        case "systemMonitor": self = .systemMonitor
        case "weather": self = .weather
        default: return nil
        }
    }
} 