import Foundation

struct TokenCounter {
    static func countTokens(in text: String) -> Int {
        // Simple token counting based on GPT-style tokenization
        // This is a rough approximation - real tokenization would be more complex
        
        if text.isEmpty {
            return 0
        }
        
        // Remove extra whitespace and normalize
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Rough estimation: 
        // - Split by whitespace and punctuation
        // - Average 4 characters per token for English text
        // - Add some overhead for special tokens
        
        let words = cleanedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        var tokenCount = 0
        
        for word in words {
            // Basic word splitting by punctuation
            let subWords = word.components(separatedBy: CharacterSet.punctuationCharacters)
                .filter { !$0.isEmpty }
            
            for subWord in subWords {
                // Approximate tokens based on character length
                let charCount = subWord.count
                let tokens = max(1, (charCount + 3) / 4) // Round up division by 4
                tokenCount += tokens
            }
            
            // Add tokens for punctuation
            let punctuationCount = word.filter { CharacterSet.punctuationCharacters.contains($0.unicodeScalars.first!) }.count
            tokenCount += punctuationCount
        }
        
        // Add some overhead for special tokens, formatting, etc.
        tokenCount = Int(Double(tokenCount) * 1.1)
        
        return max(1, tokenCount)
    }
} 