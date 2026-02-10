//
//  SMSParser.swift
//  PayGuard
//
//  Created for PayGuard
//

import Foundation

struct SMSParser {
    
    /// Parse SMS text to extract transaction information
    static func parseTransaction(from smsText: String) -> ParsedTransaction? {
        let text = smsText.lowercased()
        
        // Common patterns for Indian banks/UPI
        // Pattern 1: "₹299 debited", "Rs.499 debited"
        // Pattern 2: "Subscription renewed for ₹299"
        // Pattern 3: "Auto-debit of ₹500"
        // Pattern 4: "UPI Payment of ₹150"
        
        let amountPattern = "(?:₹|rs\\.?|inr)\\s*(\\d+(?:\\.\\d{2})?)"
        let merchantPattern = "to\\s+([A-Za-z0-9\\s]+?)(?:\\s+on|\\s+for|\\s+via|$)"
        
        guard let amountRange = text.range(of: amountPattern, options: .regularExpression) else {
            return nil
        }
        
        let amountString = String(text[amountRange])
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: "rs.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "rs", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "inr", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespaces)
        
        guard let amount = Double(amountString) else {
            return nil
        }
        
        // Extract merchant/service name
        var merchant: String? = nil
        
        // Common OTT services
        let ottServices = ["netflix", "prime video", "disney", "hotstar", "zee5", "sonyliv", "jiocinema", "youtube premium", "spotify"]
        for service in ottServices {
            if text.contains(service) {
                merchant = service.capitalized
                break
            }
        }
        
        // Common apps
        let apps = ["swiggy", "zomato", "amazon prime", "apple music", "dropbox", "onedrive", "icloud"]
        for app in apps {
            if text.contains(app) {
                merchant = app.capitalized
                break
            }
        }
        
        // Gym services
        if text.contains("gym") || text.contains("fitness") {
            merchant = "Gym/Fitness"
        }
        
        // If no merchant found, try to extract from "to X" pattern
        if merchant == nil, let merchantRange = text.range(of: merchantPattern, options: .regularExpression) {
            let extracted = String(text[merchantRange])
                .replacingOccurrences(of: "to", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "on", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "for", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespaces)
            if !extracted.isEmpty && extracted.count < 50 {
                merchant = extracted.capitalized
            }
        }
        
        // Determine if this is likely a subscription
        let subscriptionKeywords = ["subscription", "auto-debit", "renewed", "renewal", "recurring", "mandate", "auto pay"]
        let isSubscription = subscriptionKeywords.contains { text.contains($0) }
        
        // Extract date if available
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_IN")
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        var transactionDate = Date()
        
        // Try to parse date from SMS
        if let dateMatch = text.range(of: "\\d{1,2}/\\d{1,2}/\\d{4}", options: .regularExpression) {
            let dateString = String(text[dateMatch])
            if let parsedDate = dateFormatter.date(from: dateString) {
                transactionDate = parsedDate
            }
        }
        
        return ParsedTransaction(
            amount: amount,
            merchant: merchant,
            description: smsText,
            isSubscription: isSubscription,
            date: transactionDate
        )
    }
    
    /// Detect if SMS indicates a recurring payment pattern
    static func isRecurringPayment(smsText: String, previousAmount: Double?, previousMerchant: String?) -> Bool {
        let text = smsText.lowercased()
        
        // Check for subscription keywords
        let subscriptionKeywords = ["subscription", "renewed", "renewal", "recurring", "auto-debit", "auto pay"]
        if subscriptionKeywords.contains(where: { text.contains($0) }) {
            return true
        }
        
        // Check if same merchant and amount pattern (requires historical data)
        if let prevMerchant = previousMerchant, let prevAmount = previousAmount {
            let parsed = parseTransaction(from: smsText)
            if let merchant = parsed?.merchant, 
               let amount = parsed?.amount,
               merchant.lowercased() == prevMerchant.lowercased(),
               abs(amount - prevAmount) < 1.0 {
                return true
            }
        }
        
        return false
    }
}

struct ParsedTransaction {
    let amount: Double
    let merchant: String?
    let description: String
    let isSubscription: Bool
    let date: Date
}

