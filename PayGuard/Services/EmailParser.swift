//
//  EmailParser.swift
//  PayGuard
//
//  Created for PayGuard
//

import Foundation

struct EmailParser {
    
    /// Parse email content to extract subscription information
    static func parseSubscription(from emailContent: String, subject: String? = nil) -> ParsedEmailSubscription? {
        let combinedText = ((subject ?? "") + " " + emailContent).lowercased()
        
        // Check if email is subscription-related
        let subscriptionKeywords = [
            "subscription", "renewal", "renewed", "auto-debit", "recurring",
            "invoice", "receipt", "payment", "billing", "charge", "debited"
        ]
        
        let isSubscriptionRelated = subscriptionKeywords.contains { combinedText.contains($0) }
        guard isSubscriptionRelated else { return nil }
        
        // Extract amount
        let amountPattern = "(?:₹|rs\\.?|inr|usd|\\$)\\s*(\\d+(?:\\.\\d{2})?)"
        guard let amountRange = combinedText.range(of: amountPattern, options: .regularExpression) else {
            return nil
        }
        
        let amountString = String(combinedText[amountRange])
            .replacingOccurrences(of: "₹", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "rs.", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "rs", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "inr", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "$", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "usd", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespaces)
        
        guard let amount = Double(amountString) else {
            return nil
        }
        
        // Determine currency
        let currency: String
        if combinedText.contains("₹") || combinedText.contains("rs") || combinedText.contains("inr") {
            currency = "₹"
        } else if combinedText.contains("$") || combinedText.contains("usd") {
            currency = "$"
        } else {
            currency = "₹" // Default to INR
        }
        
        // Extract service/merchant name
        var serviceName: String? = nil
        
        // Common OTT services
        let ottServices = [
            "netflix", "prime video", "amazon prime", "disney", "hotstar", "disney+",
            "zee5", "sonyliv", "jiocinema", "youtube premium", "spotify", "apple music",
            "apple tv", "hulu", "hbo", "max"
        ]
        for service in ottServices {
            if combinedText.contains(service) {
                serviceName = service.capitalized
                break
            }
        }
        
        // Common apps and services
        let apps = [
            "swiggy", "zomato", "uber", "uber eats", "dropbox", "onedrive", "icloud",
            "adobe", "microsoft", "office 365", "google workspace", "notion", "figma",
            "slack", "zoom", "linkedin premium", "medium"
        ]
        if serviceName == nil {
            for app in apps {
                if combinedText.contains(app) {
                    serviceName = app.capitalized
                    break
                }
            }
        }
        
        // Gym services
        if serviceName == nil && (combinedText.contains("gym") || combinedText.contains("fitness")) {
            serviceName = "Gym/Fitness"
        }
        
        // Try to extract from email subject or sender
        if serviceName == nil {
            if let subject = subject {
                // Remove common email prefixes
                let cleaned = subject
                    .replacingOccurrences(of: "invoice", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "receipt", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "payment", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "subscription", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespaces)
                
                if !cleaned.isEmpty && cleaned.count < 50 {
                    serviceName = cleaned.capitalized
                }
            }
        }
        
        // Extract date
        var transactionDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Try various date formats
        let dateFormats = [
            "dd/MM/yyyy", "MM/dd/yyyy", "yyyy-MM-dd",
            "dd-MM-yyyy", "MMM dd, yyyy", "dd MMM yyyy"
        ]
        
        for format in dateFormats {
            dateFormatter.dateFormat = format
            if let dateMatch = combinedText.range(of: "\\d{1,2}[/-]\\d{1,2}[/-]\\d{4}", options: .regularExpression) {
                let dateString = String(combinedText[dateMatch])
                if let parsedDate = dateFormatter.date(from: dateString) {
                    transactionDate = parsedDate
                    break
                }
            }
        }
        
        // Determine frequency (default to monthly)
        var frequency: Frequency = .monthly
        if combinedText.contains("yearly") || combinedText.contains("annual") {
            frequency = .yearly
        } else if combinedText.contains("quarterly") {
            frequency = .quarterly
        } else if combinedText.contains("weekly") || combinedText.contains("week") {
            frequency = .weekly
        } else if combinedText.contains("bi-weekly") || combinedText.contains("biweekly") {
            frequency = .biWeekly
        }
        
        // Calculate next debit date based on frequency
        let nextDebitDate = Calendar.current.date(byAdding: .day, value: frequency.days, to: transactionDate) ?? Date().addingTimeInterval(30 * 24 * 60 * 60)
        
        return ParsedEmailSubscription(
            serviceName: serviceName ?? "Unknown Service",
            amount: amount,
            currency: currency,
            date: transactionDate,
            frequency: frequency,
            nextDebitDate: nextDebitDate,
            emailSubject: subject,
            emailContent: emailContent
        )
    }
}

struct ParsedEmailSubscription: Identifiable {
    let id = UUID()
    var serviceName: String
    var amount: Double
    var currency: String
    var date: Date
    var frequency: Frequency
    var nextDebitDate: Date
    var emailSubject: String?
    var emailContent: String
    
    var formattedAmount: String {
        "\(currency)\(String(format: "%.2f", amount))"
    }
}

