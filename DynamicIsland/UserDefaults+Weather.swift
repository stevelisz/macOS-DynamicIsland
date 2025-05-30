import Foundation

enum TemperatureUnit: String, CaseIterable {
    case celsius = "C"
    case fahrenheit = "F"
    
    var displayName: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
    
    func convert(_ celsius: Double) -> Double {
        switch self {
        case .celsius:
            return celsius
        case .fahrenheit:
            return (celsius * 9/5) + 32
        }
    }
}

extension UserDefaults {
    private enum Keys {
        static let temperatureUnit = "temperatureUnit"
    }
    
    var temperatureUnit: TemperatureUnit {
        get {
            let rawValue = string(forKey: Keys.temperatureUnit) ?? TemperatureUnit.celsius.rawValue
            return TemperatureUnit(rawValue: rawValue) ?? .celsius
        }
        set {
            set(newValue.rawValue, forKey: Keys.temperatureUnit)
        }
    }
} 