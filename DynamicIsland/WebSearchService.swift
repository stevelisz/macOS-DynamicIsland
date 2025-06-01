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
            return await searchDuckDuckGoHTML(query: query)
        case .disabled:
            return nil
        }
    }
    
    // MARK: - DuckDuckGo HTML Scraping Implementation
    
    private func searchDuckDuckGoHTML(query: String) async -> String? {
        do {
            // Use DuckDuckGo HTML search (no API key required)
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "https://duckduckgo.com/html/?q=\(encodedQuery)&kl=us-en"
            
            guard let url = URL(string: urlString) else {
                return "Error: Invalid search URL"
            }
            
            var request = URLRequest(url: url)
            // Add user agent to avoid blocking
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return "Error: Search request failed"
            }
            
            guard let html = String(data: data, encoding: .utf8) else {
                return "Error: Unable to decode search results"
            }
            
            return parseSearchResults(from: html, query: query)
            
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    private func parseSearchResults(from html: String, query: String) -> String {
        var results: [String] = []
        
        // Extract search results using basic HTML parsing
        let lines = html.components(separatedBy: .newlines)
        var currentResult: [String: String] = [:]
        var isInResult = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Look for result titles (simplified pattern matching)
            if trimmedLine.contains("class=\"result__title\"") || trimmedLine.contains("class=\"links_main\"") {
                isInResult = true
                // Extract title from the line
                if let titleMatch = extractTitle(from: trimmedLine) {
                    currentResult["title"] = titleMatch
                }
            }
            
            // Look for snippets
            if isInResult && (trimmedLine.contains("class=\"result__snippet\"") || trimmedLine.contains("class=\"snippet\"")) {
                if let snippet = extractSnippet(from: trimmedLine) {
                    currentResult["snippet"] = snippet
                }
            }
            
            // Look for URLs
            if isInResult && trimmedLine.contains("href=") {
                if let url = extractURL(from: trimmedLine) {
                    currentResult["url"] = url
                }
            }
            
            // End of result
            if isInResult && trimmedLine.contains("</div>") && !currentResult.isEmpty {
                if let title = currentResult["title"], 
                   let snippet = currentResult["snippet"] {
                    let resultText = "**\(title)**\n\(snippet)"
                    if let url = currentResult["url"] {
                        results.append("\(resultText)\n🔗 \(url)")
                    } else {
                        results.append(resultText)
                    }
                }
                currentResult = [:]
                isInResult = false
            }
        }
        
        // If we didn't get structured results, try a simpler approach
        if results.isEmpty {
            return parseSearchResultsSimple(from: html, query: query)
        }
        
        if results.isEmpty {
            return "No search results found for '\(query)'. This may be due to rate limiting or changes in the search page structure."
        }
        
        let limitedResults = Array(results.prefix(5)) // Limit to top 5 results
        return limitedResults.joined(separator: "\n\n")
    }
    
    private func parseSearchResultsSimple(from html: String, query: String) -> String {
        // Fallback: Look for any text that seems like search results
        var results: [String] = []
        
        // Look for common patterns that indicate search result content
        let patterns = [
            "2024", "recent", "news", "latest", "current", "today",
            "happened", "events", "election", "war", "conflict"
        ]
        
        let lines = html.components(separatedBy: .newlines)
        var relevantContent: [String] = []
        
        for line in lines {
            let cleanLine = line.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if cleanLine.count > 50 && cleanLine.count < 300 {
                let lowerLine = cleanLine.lowercased()
                let matchCount = patterns.filter { lowerLine.contains($0) }.count
                
                if matchCount >= 2 || lowerLine.contains(query.lowercased()) {
                    relevantContent.append(cleanLine)
                }
            }
        }
        
        // Remove duplicates and take top results
        let uniqueContent = Array(Set(relevantContent)).prefix(3)
        
        if uniqueContent.isEmpty {
            return "Search completed but no relevant current information found. The query '\(query)' may require more specific terms or recent events may not be indexed yet."
        }
        
        return uniqueContent.joined(separator: "\n\n")
    }
    
    private func extractTitle(from html: String) -> String? {
        // Extract text between > and < tags
        if let startRange = html.range(of: ">"),
           let endRange = html.range(of: "<", options: [], range: startRange.upperBound..<html.endIndex) {
            let title = String(html[startRange.upperBound..<endRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return title.isEmpty ? nil : title
        }
        return nil
    }
    
    private func extractSnippet(from html: String) -> String? {
        // Extract text content, removing HTML tags
        let cleanText = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanText.isEmpty ? nil : cleanText
    }
    
    private func extractURL(from html: String) -> String? {
        // Extract URL from href attribute
        if let hrefRange = html.range(of: "href=\""),
           let endQuoteRange = html.range(of: "\"", options: [], range: hrefRange.upperBound..<html.endIndex) {
            let url = String(html[hrefRange.upperBound..<endQuoteRange.lowerBound])
            // Clean up relative URLs
            if url.hasPrefix("//") {
                return "https:" + url
            } else if url.hasPrefix("/") {
                return "https://duckduckgo.com" + url
            }
            return url.hasPrefix("http") ? url : nil
        }
        return nil
    }
    
    // MARK: - Search Query Enhancement
    
    func enhanceQueryWithSearch(originalQuery: String, searchProvider: SearchProvider) async -> String {
        guard searchProvider != .disabled else { return originalQuery }
        
        if let searchResults = await searchWeb(query: originalQuery, provider: searchProvider) {
            return """
            **Original Question:** \(originalQuery)
            
            **Web Search Results:**
            \(searchResults)
            
            **Instructions:** Based on the web search results above, please provide a comprehensive answer to the original question. Use the search results as context and synthesize the information to give a complete response. Focus on the most relevant and recent information from the search results.
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
            "2024", "2025", "now", "date", "time", "when", "happened",
            
            // Question words that often need current info
            "what's", "what is", "what are", "how to", "where is", "when did", "who is",
            "how much", "what time", "what date", "what happened",
            
            // Current events/data
            "stock price", "weather", "score", "election", "breaking", "update",
            "price of", "cost of", "exchange rate", "temperature", "events"
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