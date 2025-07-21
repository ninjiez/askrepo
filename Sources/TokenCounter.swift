
import Foundation
import Tiktoken

struct TokenCounter {
    static func countTokens(in text: String) -> Int {
        guard !text.isEmpty else {
            return 0
        }
        
        // For the synchronous version, we'll use the fallback estimate
        // since we can't easily await in a sync function
        // This provides a consistent, fast estimate
        return max(1, text.count / 4)
    }
    
    /// Async version for better performance
    static func countTokensAsync(in text: String) async -> Int {
        guard !text.isEmpty else {
            return 0
        }
        
        do {
            if let encoding = try await Tiktoken.shared.getEncoding("cl100k_base") {
                let tokens = encoding.encode(value: text)
                return tokens.count
            }
        } catch {
            print("Error getting Tiktoken encoding: \(error)")
        }
        
        // Fallback to a rough estimate
        return text.count / 4
    }
}
 