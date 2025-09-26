
import Foundation
import Tiktoken

private actor TokenEncodingProvider {
    static let shared = TokenEncodingProvider()

    private var cachedEncoding: Encoding?
    private enum TokenEncodingError: Error {
        case encodingUnavailable
    }

    func encoding() async throws -> Encoding {
        if let cachedEncoding {
            return cachedEncoding
        }

        guard let encoding = try await Tiktoken.shared.getEncoding("cl100k_base") else {
            throw TokenEncodingError.encodingUnavailable
        }
        cachedEncoding = encoding
        return encoding
    }
}

struct TokenCounter {
    static func countTokens(in text: String) -> Int {
        guard !text.isEmpty else {
            return 0
        }

        // Rough estimate used when async workflow is not available
        return max(1, text.count / 4)
    }
    
    /// Async version that relies on the shared cached encoding for accuracy
    static func countTokensAsync(in text: String) async -> Int {
        guard !text.isEmpty else {
            return 0
        }
        
        do {
            let encoding = try await TokenEncodingProvider.shared.encoding()
            let tokens = encoding.encode(value: text)
            return tokens.count
        } catch {
            print("Error getting Tiktoken encoding: \(error)")
        }
        
        // Fallback to a rough estimate if encoding retrieval fails
        return max(1, text.count / 4)
    }
}
