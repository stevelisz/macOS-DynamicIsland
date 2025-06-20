import Foundation

extension UserDefaults {
    private enum Keys {
        static let lastSelectedTab = "lastSelectedTab"
        static let enabledTabs = "enabledTabs"
        static let tabOrder = "tabOrder"
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
            return Set([.clipboard, .quickApp, .systemMonitor, .weather, .timer, .unitConverter, .calendar, .developerTools, .aiAssistant])
        }
        set {
            let rawValues = newValue.map { $0.rawValue }
            set(rawValues, forKey: Keys.enabledTabs)
        }
    }
    
    var tabOrder: [MainViewType] {
        get {
            if let rawValues = array(forKey: Keys.tabOrder) as? [String] {
                let orderedTypes = rawValues.compactMap { MainViewType(rawValue: $0) }
                // If the stored order is incomplete, fill with default order
                if orderedTypes.count == MainViewType.allCases.count {
                    return orderedTypes
                }
            }
            // Default order
            return [.clipboard, .quickApp, .systemMonitor, .weather, .timer, .unitConverter, .calendar, .developerTools, .aiAssistant]
        }
        set {
            let rawValues = newValue.map { $0.rawValue }
            set(rawValues, forKey: Keys.tabOrder)
        }
    }
    
    func moveTab(from sourceIndex: Int, to destinationIndex: Int) {
        var currentOrder = tabOrder
        let movedTab = currentOrder.remove(at: sourceIndex)
        currentOrder.insert(movedTab, at: destinationIndex)
        tabOrder = currentOrder
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
        case .unitConverter: return "unitConverter"
        case .calendar: return "calendar"
        case .developerTools: return "developerTools"
        case .aiAssistant: return "aiAssistant"
        }
    }
    
    public init?(rawValue: String) {
        switch rawValue {
        case "clipboard": self = .clipboard
        case "quickApp": self = .quickApp
        case "systemMonitor": self = .systemMonitor
        case "weather": self = .weather
        case "timer": self = .timer
        case "unitConverter": self = .unitConverter
        case "calendar": self = .calendar
        case "developerTools": self = .developerTools
        case "aiAssistant": self = .aiAssistant
        default: return nil
        }
    }
} 