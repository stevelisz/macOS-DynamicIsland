import Foundation
import CoreLocation
import SwiftUI
import Combine

// Weather Models
struct WeatherData {
    let currentTemperature: Double
    let condition: String
    let conditionSymbol: String
    let humidity: Double
    let windSpeed: Double
    let location: String
    let hourlyForecast: [HourlyWeather]
    let dailyForecast: [DailyWeather]
    let uvIndex: Int
    let visibility: Double
    let feelsLike: Double
    
    static let placeholder = WeatherData(
        currentTemperature: 22,
        condition: "Partly Cloudy",
        conditionSymbol: "cloud.sun.fill",
        humidity: 65,
        windSpeed: 8.5,
        location: "San Francisco",
        hourlyForecast: [],
        dailyForecast: [],
        uvIndex: 6,
        visibility: 10.0,
        feelsLike: 24
    )
}

struct HourlyWeather: Identifiable {
    let id = UUID()
    let time: Date
    let temperature: Double
    let symbol: String
    let precipitationChance: Double
}

struct DailyWeather: Identifiable {
    let id = UUID()
    let date: Date
    let high: Double
    let low: Double
    let symbol: String
    let precipitationChance: Double
    let condition: String
}

// Simple Weather API Response Models
struct WeatherAPIResponse: Codable {
    let coord: Coordinates
    let weather: [WeatherCondition]
    let main: MainWeather
    let visibility: Int
    let wind: Wind
    let name: String
}

struct Coordinates: Codable {
    let lat: Double
    let lon: Double
}

struct WeatherCondition: Codable {
    let main: String
    let description: String
    let icon: String
}

struct MainWeather: Codable {
    let temp: Double
    let feels_like: Double
    let humidity: Double
}

struct Wind: Codable {
    let speed: Double
}

// Weather Service using free weather API
@MainActor
class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentWeather: WeatherData = WeatherData.placeholder
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    // Using free weather service that doesn't require API key
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationPermissionStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        locationManager.requestLocation()
    }
    
    func fetchWeather() {
        guard locationPermissionStatus == .authorizedAlways else {
            errorMessage = "Location access required for weather data"
            return
        }
        
        guard let location = currentLocation else {
            locationManager.requestLocation()
            return
        }
        
        Task {
            await fetchWeatherData(for: location)
        }
    }
    
    private func fetchWeatherData(for location: CLLocation) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            
            // Using Open-Meteo free weather API (no API key required)
            let urlString = "\(baseURL)?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,relative_humidity_2m,apparent_temperature,wind_speed_10m,weather_code&hourly=temperature_2m,weather_code,precipitation_probability&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max&timezone=auto"
            
            guard let url = URL(string: urlString) else {
                errorMessage = "Invalid URL"
                isLoading = false
                return
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            
            let locationName = await getLocationName(for: location)
            
            // Create proper date formatters for Open-Meteo API
            let hourlyFormatter = DateFormatter()
            hourlyFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            hourlyFormatter.timeZone = TimeZone.current
            
            let dailyFormatter = DateFormatter()
            dailyFormatter.dateFormat = "yyyy-MM-dd"
            dailyFormatter.timeZone = TimeZone.current
            
            // Generate hourly forecast (next 12 hours from current time)
            let currentDate = Date()
            let calendar = Calendar.current
            let currentHour = calendar.component(.hour, from: currentDate)
            
            // Find the starting index for current hour or next hour
            var startIndex = 0
            for (index, timeString) in response.hourly.time.enumerated() {
                if let date = hourlyFormatter.date(from: timeString) {
                    let hour = calendar.component(.hour, from: date)
                    if hour >= currentHour && calendar.isDate(date, inSameDayAs: currentDate) {
                        startIndex = index
                        break
                    }
                }
            }
            
            let hourlyForecasts: [HourlyWeather] = Array(startIndex..<min(startIndex + 12, response.hourly.time.count)).compactMap { index in
                guard let date = hourlyFormatter.date(from: response.hourly.time[index]) else {
                    return nil
                }
                return HourlyWeather(
                    time: date,
                    temperature: response.hourly.temperature_2m[index],
                    symbol: getSymbolForWeatherCode(response.hourly.weather_code[index]),
                    precipitationChance: (response.hourly.precipitation_probability?[index] ?? 0) / 100.0
                )
            }
            
            // Generate daily forecast (next 7 days)
            let dailyForecasts: [DailyWeather] = Array(0..<min(7, response.daily.time.count)).compactMap { index in
                guard let date = dailyFormatter.date(from: response.daily.time[index]) else {
                    return nil
                }
                return DailyWeather(
                    date: date,
                    high: response.daily.temperature_2m_max[index],
                    low: response.daily.temperature_2m_min[index],
                    symbol: getSymbolForWeatherCode(response.daily.weather_code[index]),
                    precipitationChance: (response.daily.precipitation_probability_max?[index] ?? 0) / 100.0,
                    condition: getConditionForWeatherCode(response.daily.weather_code[index])
                )
            }
            
            let weatherData = WeatherData(
                currentTemperature: response.current.temperature_2m,
                condition: getConditionForWeatherCode(response.current.weather_code),
                conditionSymbol: getSymbolForWeatherCode(response.current.weather_code),
                humidity: response.current.relative_humidity_2m / 100.0,
                windSpeed: response.current.wind_speed_10m,
                location: locationName,
                hourlyForecast: hourlyForecasts,
                dailyForecast: dailyForecasts,
                uvIndex: 5, // Default value since not available in free API
                visibility: 10.0, // Default value
                feelsLike: response.current.apparent_temperature
            )
            
            currentWeather = weatherData
            isLoading = false
            
        } catch {
            print("Weather fetch error: \(error)")
            errorMessage = "Failed to fetch weather: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func getSymbolForWeatherCode(_ code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1: return "sun.max.fill"
        case 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55: return "cloud.drizzle.fill"
        case 61, 63, 65: return "cloud.rain.fill"
        case 71, 73, 75: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "questionmark.circle"
        }
    }
    
    private func getConditionForWeatherCode(_ code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1: return "Mainly Clear"
        case 2: return "Partly Cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 61, 63, 65: return "Rain"
        case 71, 73, 75: return "Snow"
        case 95, 96, 99: return "Thunderstorm"
        default: return "Unknown"
        }
    }
    
    private func getLocationName(for location: CLLocation) async -> String {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                return placemark.locality ?? placemark.administrativeArea ?? "Current Location"
            }
        } catch {
            print("Geocoding error: \(error)")
        }
        return "Current Location"
    }
    
    // MARK: - CLLocationManagerDelegate
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            currentLocation = location
            await fetchWeatherData(for: location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = "Location error: \(error.localizedDescription)"
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            locationPermissionStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedAlways:
                fetchWeather()
            case .denied, .restricted:
                errorMessage = "Location access denied. Please enable in System Settings."
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}

// Open-Meteo API Response Models
struct OpenMeteoResponse: Codable {
    let current: CurrentWeather
    let hourly: HourlyData
    let daily: DailyData
}

struct CurrentWeather: Codable {
    let temperature_2m: Double
    let relative_humidity_2m: Double
    let apparent_temperature: Double
    let wind_speed_10m: Double
    let weather_code: Int
}

struct HourlyData: Codable {
    let time: [String]
    let temperature_2m: [Double]
    let weather_code: [Int]
    let precipitation_probability: [Double]?
}

struct DailyData: Codable {
    let time: [String]
    let temperature_2m_max: [Double]
    let temperature_2m_min: [Double]
    let weather_code: [Int]
    let precipitation_probability_max: [Double]?
} 