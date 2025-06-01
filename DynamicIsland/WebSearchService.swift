import Foundation

@MainActor
class WebSearchService: ObservableObject {
    @Published var isSearching = false
    
    private let session = URLSession.shared
    
    // MARK: - Search Provider Configuration
    
    enum SearchProvider: String, CaseIterable {
        case duckduckgo = "DuckDuckGo"
        case disabled = "Disabled"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    // MARK: - Search Methods
    
    func searchWeb(query: String, provider: SearchProvider = .duckduckgo) async -> String? {
        guard provider != .disabled else { return nil }
        
        isSearching = true
        defer { isSearching = false }
        
        switch provider {
        case .duckduckgo:
            return await searchDuckDuckGo(query: query)
        case .disabled:
            return nil
        }
    }
    
    // MARK: - DuckDuckGo Implementation
    
    private func searchDuckDuckGo(query: String) async -> String? {
        do {
            // DuckDuckGo Instant Answer API (free, no API key required)
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "https://api.duckduckgo.com/?q=\(encodedQuery)&format=json&no_html=1&skip_disambig=1"
            
            guard let url = URL(string: urlString) else {
                return "Error: Invalid search URL"
            }
            
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return "Error: Search request failed"
            }
            
            if let searchResults = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return formatDuckDuckGoResults(searchResults)
            }
            
            return "No search results found"
            
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    private func formatDuckDuckGoResults(_ results: [String: Any]) -> String {
        var formattedResults: [String] = []
        
        // Add instant answer if available
        if let abstract = results["Abstract"] as? String, !abstract.isEmpty {
            formattedResults.append("**Answer:** \(abstract)")
            
            if let source = results["AbstractSource"] as? String, !source.isEmpty {
                formattedResults.append("*Source: \(source)*")
            }
            
            if let url = results["AbstractURL"] as? String, !url.isEmpty {
                formattedResults.append("🔗 [\(url)](\(url))")
            }
        }
        
        // Add definition if available
        if let definition = results["Definition"] as? String, !definition.isEmpty {
            formattedResults.append("**Definition:** \(definition)")
            
            if let source = results["DefinitionSource"] as? String, !source.isEmpty {
                formattedResults.append("*Source: \(source)*")
            }
        }
        
        // Add related topics
        if let relatedTopics = results["RelatedTopics"] as? [[String: Any]], !relatedTopics.isEmpty {
            formattedResults.append("\n**Related Information:**")
            
            for (index, topic) in relatedTopics.prefix(3).enumerated() {
                if let text = topic["Text"] as? String, !text.isEmpty {
                    formattedResults.append("\(index + 1). \(text)")
                    
                    if let firstURL = topic["FirstURL"] as? String, !firstURL.isEmpty {
                        formattedResults.append("   🔗 [\(firstURL)](\(firstURL))")
                    }
                }
            }
        }
        
        // Add answer if available (for calculations, conversions, etc.)
        if let answer = results["Answer"] as? String, !answer.isEmpty {
            formattedResults.append("**Result:** \(answer)")
        }
        
        if formattedResults.isEmpty {
            return "No detailed results found for your search query."
        }
        
        return formattedResults.joined(separator: "\n\n")
    }
    
    // MARK: - Search Query Enhancement
    
    func enhanceQueryWithSearch(originalQuery: String, searchProvider: SearchProvider) async -> String {
        guard searchProvider != .disabled else { return originalQuery }
        
        if let searchResults = await searchWeb(query: originalQuery, provider: searchProvider) {
            return """
            **Original Question:** \(originalQuery)
            
            **Web Search Results:**
            \(searchResults)
            
            **Instructions:** Based on the web search results above, please provide a comprehensive answer to the original question. Use the search results as context but also apply your knowledge to give a complete response.
            """
        }
        
        return originalQuery
    }
    
    // MARK: - Helper Methods
    
    func isWebSearchQuery(_ query: String) -> Bool {
        let webSearchIndicators = [
            "current", "latest", "recent", "news", "today", "2024", "2025",
            "what's", "what is", "how to", "where is", "when did", "who is",
            "stock price", "weather", "score", "election", "breaking"
        ]
        
        let lowercaseQuery = query.lowercased()
        return webSearchIndicators.contains { lowercaseQuery.contains($0) }
    }
    
    func shouldSuggestWebSearch(_ query: String) -> Bool {
        let webSearchIndicators = [
            // Time/Date related
            "current", "latest", "recent", "news", "today", "tomorrow", "yesterday", 
            "2024", "2025", "now", "date", "time", "when",
            
            // Question words that often need current info
            "what's", "what is", "what are", "how to", "where is", "when did", "who is",
            "how much", "what time", "what date",
            
            // Current events/data
            "stock price", "weather", "score", "election", "breaking", "update",
            "price of", "cost of", "exchange rate", "temperature"
        ]
        
        let lowercaseQuery = query.lowercased()
        return webSearchIndicators.contains { lowercaseQuery.contains($0) }
    }
}

// MARK: - Supporting Models

struct SearchResult {
    let title: String
    let snippet: String
    let url: String
    let source: String?
}

extension UserDefaults {
    private enum Keys {
        static let webSearchProvider = "webSearchProvider"
        static let webSearchEnabled = "webSearchEnabled"
    }
    
    var webSearchProvider: WebSearchService.SearchProvider {
        get {
            if let providerString = string(forKey: Keys.webSearchProvider),
               let provider = WebSearchService.SearchProvider(rawValue: providerString) {
                return provider
            }
            return .disabled // Default to disabled for privacy
        }
        set {
            set(newValue.rawValue, forKey: Keys.webSearchProvider)
        }
    }
    
    var webSearchEnabled: Bool {
        get {
            return webSearchProvider != .disabled
        }
        set {
            webSearchProvider = newValue ? .duckduckgo : .disabled
        }
    }
} 