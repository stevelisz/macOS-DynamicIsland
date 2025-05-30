import SwiftUI
import CoreLocation

struct WeatherView: View {
    @StateObject private var weatherService = WeatherService()
    @State private var selectedForecastType: ForecastType = .hourly
    
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
            // Location and main temperature
            VStack(spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(weatherService.currentWeather.location)
                        .font(DesignSystem.Typography.micro)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Spacer()
                }
                
                HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("\(Int(weatherService.currentWeather.currentTemperature))°")
                            .font(.system(size: 48, weight: .thin))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(weatherService.currentWeather.condition)
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text("Feels like \(Int(weatherService.currentWeather.feelsLike))°")
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
                        
                        Image(systemName: hour.symbol)
                            .font(.system(size: 20))
                            .foregroundColor(getWeatherColor(for: hour.symbol))
                            .symbolRenderingMode(.hierarchical)
                        
                        Text("\(Int(hour.temperature))°")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if hour.precipitationChance > 0 {
                            Text("\(Int(hour.precipitationChance * 100))%")
                                .font(.system(size: 8))
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
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
                        .frame(width: 50, alignment: .leading)
                    
                    Image(systemName: day.symbol)
                        .font(.system(size: 16))
                        .foregroundColor(getWeatherColor(for: day.symbol))
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 20)
                    
                    if day.precipitationChance > 0 {
                        Text("\(Int(day.precipitationChance * 100))%")
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.primary)
                            .frame(width: 30)
                    } else {
                        Spacer().frame(width: 30)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text("\(Int(day.low))°")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text("\(Int(day.high))°")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
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