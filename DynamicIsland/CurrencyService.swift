import Foundation
import SwiftUI

// Currency Exchange Models
struct ExchangeRates {
    let baseCurrency: String
    let rates: [String: Double]
    let lastUpdated: Date
    
    static let fallback = ExchangeRates(
        baseCurrency: "USD",
        rates: [
            "USD": 1.0,
            "EUR": 0.92,
            "GBP": 0.79,
            "JPY": 149.50,
            "CAD": 1.35,
            "AUD": 1.52,
            "CHF": 0.88,
            "CNY": 7.24
        ],
        lastUpdated: Date()
    )
}

// API Response Models
struct ExchangeRateAPIResponse: Codable {
    let base: String
    let date: String
    let rates: [String: Double]
}

@MainActor
class CurrencyService: ObservableObject {
    @Published var exchangeRates: ExchangeRates = .fallback
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    
    private let baseURL = "https://api.exchangerate-api.com/v4/latest"
    private let cacheKey = "CachedExchangeRates"
    private let cacheTimeKey = "CachedExchangeRatesTime"
    private let cacheValidityDuration: TimeInterval = 3600 // 1 hour
    
    init() {
        loadCachedRates()
        
        // Fetch fresh rates if cache is old or missing
        if shouldFetchFreshRates() {
            Task {
                await fetchExchangeRates()
            }
        }
    }
    
    func refreshRates() async {
        await fetchExchangeRates()
    }
    
    func convertCurrency(_ amount: Double, from: String, to: String) -> Double {
        guard from != to else { return amount }
        
        let rates = exchangeRates.rates
        
        // Convert from base currency (USD) to target
        if from == exchangeRates.baseCurrency {
            return amount * (rates[to] ?? 1.0)
        }
        
        // Convert to base currency first, then to target
        let baseAmount = amount / (rates[from] ?? 1.0)
        return baseAmount * (rates[to] ?? 1.0)
    }
    
    func getRateString(from: String, to: String) -> String {
        let rate = convertCurrency(1.0, from: from, to: to)
        return String(format: "%.4f", rate)
    }
    
    private func fetchExchangeRates() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Using ExchangeRate-API (free tier: 1500 requests/month)
            let url = URL(string: "\(baseURL)/USD")!
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(ExchangeRateAPIResponse.self, from: data)
            
            let newRates = ExchangeRates(
                baseCurrency: response.base,
                rates: response.rates,
                lastUpdated: Date()
            )
            
            exchangeRates = newRates
            lastUpdateTime = Date()
            
            // Cache the rates
            cacheRates(newRates)
            
        } catch {
            errorMessage = "Failed to fetch exchange rates: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func shouldFetchFreshRates() -> Bool {
        guard let lastCacheTime = UserDefaults.standard.object(forKey: cacheTimeKey) as? Date else {
            return true // No cache time found
        }
        
        return Date().timeIntervalSince(lastCacheTime) > cacheValidityDuration
    }
    
    private func loadCachedRates() {
        guard let cachedData = UserDefaults.standard.data(forKey: cacheKey),
              let cachedTime = UserDefaults.standard.object(forKey: cacheTimeKey) as? Date else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let cachedRatesData = try decoder.decode(CachedExchangeRates.self, from: cachedData)
            
            exchangeRates = ExchangeRates(
                baseCurrency: cachedRatesData.baseCurrency,
                rates: cachedRatesData.rates,
                lastUpdated: cachedTime
            )
            lastUpdateTime = cachedTime
            
        } catch {
        }
    }
    
    private func cacheRates(_ rates: ExchangeRates) {
        do {
            let cacheData = CachedExchangeRates(
                baseCurrency: rates.baseCurrency,
                rates: rates.rates
            )
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(cacheData)
            
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(rates.lastUpdated, forKey: cacheTimeKey)
            
        } catch {
        }
    }
    
    func getTimeSinceLastUpdate() -> String {
        guard let lastUpdate = lastUpdateTime else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdate, relativeTo: Date())
    }
}

// Helper struct for caching
private struct CachedExchangeRates: Codable {
    let baseCurrency: String
    let rates: [String: Double]
}

// Extension to get currency symbols
extension String {
    var currencySymbol: String {
        switch self.uppercased() {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "CAD": return "C$"
        case "AUD": return "A$"
        case "CHF": return "CHF"
        case "CNY": return "¥"
        default: return self
        }
    }
    
    var currencyName: String {
        switch self.uppercased() {
        case "USD": return "US Dollar"
        case "EUR": return "Euro"
        case "GBP": return "British Pound"
        case "JPY": return "Japanese Yen"
        case "CAD": return "Canadian Dollar"
        case "AUD": return "Australian Dollar"
        case "CHF": return "Swiss Franc"
        case "CNY": return "Chinese Yuan"
        default: return self
        }
    }
} 