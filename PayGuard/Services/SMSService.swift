//
//  SMSService.swift
//  PayGuard
//
//  Created for PayGuard
//

import Foundation
import MessageUI
import Combine

@MainActor
class SMSService: NSObject, ObservableObject {
    static let shared = SMSService()
    
    @Published var hasPermission: Bool = false
    @Published var lastScannedDate: Date?
    @Published var errorMessage: String?
    
    private override init() {
        super.init()
        checkPermission()
    }
    
    func checkPermission() {
        // Note: iOS doesn't allow direct SMS reading due to privacy restrictions
        // This is a limitation. In a real app, you might need to:
        // 1. Use SMS forwarding to email and read from there
        // 2. Manual entry by user
        // 3. Bank API integration (if available)
        // 4. Transaction SMS forwarding to app via shortcuts
        
        // For now, we'll simulate permission and allow manual entry
        // In production, you'd request SMS read permission (if iOS allows)
        hasPermission = false // iOS restricts SMS reading
        errorMessage = "iOS restricts direct SMS reading. Please enter transactions manually or use SMS forwarding."
    }
    
    /// Request SMS reading permission
    func requestPermission() {
        // This would typically show a permission dialog
        // Since iOS doesn't allow direct SMS reading, we'll use a workaround:
        // Guide users to forward SMS to the app or enter manually
        checkPermission()
    }
    
    /// Process SMS text (can be from forwarding or manual entry)
    func processSMSText(_ text: String) -> ParsedTransaction? {
        return SMSParser.parseTransaction(from: text)
    }
    
    /// Simulate SMS scanning (for development/testing)
    func simulateSMSScan() -> [ParsedTransaction] {
        // Sample SMS messages for testing
        let sampleSMS = [
            "Netflix subscription renewed. ₹499 debited from your account. Balance: ₹5,432.10",
            "Amazon Prime Video ₹299 auto-debit successful. Transaction ID: AX123456",
            "Your gym membership fee of ₹1,200 has been debited. Thank you!",
            "Spotify Premium ₹99 debited from account ending 1234",
            "Zomato Pro subscription ₹299 renewed successfully"
        ]
        
        return sampleSMS.compactMap { SMSParser.parseTransaction(from: $0) }
    }
}
