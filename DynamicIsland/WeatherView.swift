import SwiftUI
import CoreLocation

struct WeatherView: View {
    @StateObject private var weatherService = WeatherService()
    @State private var selectedForecastType: ForecastType = .hourly
    @State private var temperatureUnit: TemperatureUnit = UserDefaults.standard.temperatureUnit
    
    enum ForecastType: String, CaseIterable {
        case hourly = "Hourly"
        case daily = "Daily"
        
        var icon: String {
            switch self {
            case .hourly: return "clock"
            case .daily: return "calendar"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if weatherService.locationPermissionStatus == .notDetermined {
                // Permission request
                permissionRequestView
            } else if weatherService.isLoading {
                // Loading state
                loadingView
            } else if let error = weatherService.errorMessage {
                // Error state
                errorView(error)
            } else {
                // Weather content
                weatherContent
            }
        }
        .onAppear {
            if weatherService.locationPermissionStatus == .authorizedAlways {
                weatherService.fetchWeather()
            }
        }
    }
    
    private var permissionRequestView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.primary)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Location Access Needed")
                    .font(DesignSystem.Typography.headline3)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("To show accurate weather for your location")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                weatherService.requestLocationPermission()
            }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text("Allow Location")
                        .font(DesignSystem.Typography.captionMedium)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(DesignSystem.BorderRadius.lg)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, DesignSystem.Spacing.xl)
    }
    
    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
            
            Text("Fetching weather...")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.vertical, DesignSystem.Spacing.xl)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(DesignSystem.Colors.warning)
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Weather Unavailable")
                    .font(DesignSystem.Typography.headline3)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(error)
                    .font(DesignSystem.Typography.micro)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            Button(action: {
                weatherService.fetchWeather()
            }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .medium))
                    Text("Retry")
                        .font(DesignSystem.Typography.micro)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.surface)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .cornerRadius(DesignSystem.BorderRadius.md)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
    
    private var weatherContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Current weather
            currentWeatherSection
            
            // Forecast toggle
            forecastToggle
            
            // Forecast content
            forecastSection
        }
    }
    
    private var currentWeatherSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Location and temperature unit toggle
            VStack(spacing: DesignSystem.Spacing.xs) {
                HStack {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text(weatherService.currentWeather.location)
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Temperature unit toggle
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                            Button(action: {
                                temperatureUnit = unit
                                UserDefaults.standard.temperatureUnit = unit
                            }) {
                                Text(unit.displayName)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(temperatureUnit == unit ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                                    .padding(.horizontal, DesignSystem.Spacing.xs)
                                    .padding(.vertical, 2)
                                    .background(temperatureUnit == unit ? DesignSystem.Colors.primary.opacity(0.2) : Color.clear)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(formatTemperature(weatherService.currentWeather.currentTemperature, showUnit: false))
                            .font(.system(size: 48, weight: .thin))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(weatherService.currentWeather.condition)
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text("Feels like \(formatTemperature(weatherService.currentWeather.feelsLike, showUnit: false))")
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: weatherService.currentWeather.conditionSymbol)
                        .font(.system(size: 40))
                        .foregroundColor(getWeatherColor(for: weatherService.currentWeather.conditionSymbol))
                        .symbolRenderingMode(.hierarchical)
                }
            }
            
            // Weather details
            HStack(spacing: DesignSystem.Spacing.sm) {
                WeatherDetailCard(
                    icon: "humidity.fill",
                    title: "Humidity",
                    value: "\(Int(weatherService.currentWeather.humidity * 100))%",
                    color: .blue
                )
                
                WeatherDetailCard(
                    icon: "wind",
                    title: "Wind",
                    value: "\(Int(weatherService.currentWeather.windSpeed)) km/h",
                    color: .green
                )
                
                WeatherDetailCard(
                    icon: "sun.max.fill",
                    title: "UV Index",
                    value: "\(weatherService.currentWeather.uvIndex)",
                    color: .orange
                )
            }
        }
    }
    
    private var forecastToggle: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(ForecastType.allCases, id: \.self) { type in
                Button(action: {
                    selectedForecastType = type
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: type.icon)
                            .font(.system(size: 10, weight: .medium))
                        Text(type.rawValue)
                            .font(DesignSystem.Typography.micro)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(selectedForecastType == type ? DesignSystem.Colors.primary.opacity(0.2) : DesignSystem.Colors.surface)
                    .foregroundColor(selectedForecastType == type ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                    .cornerRadius(DesignSystem.BorderRadius.md)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
    }
    
    private var forecastSection: some View {
        Group {
            if selectedForecastType == .hourly {
                hourlyForecast
            } else {
                dailyForecast
            }
        }
    }
    
    private var hourlyForecast: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(weatherService.currentWeather.hourlyForecast) { hour in
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text(formatTime(hour.time))
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .lineLimit(1)
                        
                        Image(systemName: hour.symbol)
                            .font(.system(size: 18))
                            .foregroundColor(getWeatherColor(for: hour.symbol))
                            .symbolRenderingMode(.hierarchical)
                            .frame(height: 20)
                        
                        Text(formatTemperature(hour.temperature))
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                        
                        // Always show precipitation area to maintain consistent height
                        Text(hour.precipitationChance > 0 ? "\(Int(hour.precipitationChance * 100))%" : " ")
                            .font(.system(size: 8))
                            .foregroundColor(hour.precipitationChance > 0 ? DesignSystem.Colors.primary : Color.clear)
                            .lineLimit(1)
                            .frame(height: 10)
                    }
                    .frame(width: 55, height: 80)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                    .background(DesignSystem.Colors.surfaceElevated)
                    .cornerRadius(DesignSystem.BorderRadius.md)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
        }
    }
    
    private var dailyForecast: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(weatherService.currentWeather.dailyForecast) { day in
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text(formatDay(day.date))
                        .font(DesignSystem.Typography.captionMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .frame(width: 60, alignment: .leading)
                        .lineLimit(1)
                    
                    Image(systemName: day.symbol)
                        .font(.system(size: 16))
                        .foregroundColor(getWeatherColor(for: day.symbol))
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 20, height: 20)
                    
                    Text(day.precipitationChance > 0 ? "\(Int(day.precipitationChance * 100))%" : " ")
                        .font(DesignSystem.Typography.micro)
                        .foregroundColor(day.precipitationChance > 0 ? DesignSystem.Colors.primary : Color.clear)
                        .frame(width: 30, alignment: .leading)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(formatTemperature(day.low))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .lineLimit(1)
                        
                        Text(formatTemperature(day.high))
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                    }
                }
                .frame(height: 40)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.surfaceElevated)
                .cornerRadius(DesignSystem.BorderRadius.md)
            }
        }
    }
    
    private func getWeatherColor(for symbol: String) -> Color {
        switch symbol {
        case let s where s.contains("sun"):
            return .orange
        case let s where s.contains("cloud"):
            return .gray
        case let s where s.contains("rain"):
            return .blue
        case let s where s.contains("snow"):
            return .white
        case let s where s.contains("bolt"):
            return .purple
        default:
            return DesignSystem.Colors.primary
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
    }
    
    private func formatTemperature(_ celsius: Double, showUnit: Bool = true) -> String {
        let convertedTemp = temperatureUnit.convert(celsius)
        let formattedValue = String(format: "%.0f", convertedTemp)
        
        if showUnit {
            return "\(formattedValue)°"
        } else {
            return "\(formattedValue)°"
        }
    }
}

struct WeatherDetailCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 8))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(value)
                    .font(DesignSystem.Typography.micro)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.surfaceElevated)
        .cornerRadius(DesignSystem.BorderRadius.md)
    }
} 