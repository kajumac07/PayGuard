//
//  Subscription.swift
//  PayGuard
//
//  Created for PayGuard
//

import Foundation

struct Subscription: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var amount: Double
    var currency: String
    var frequency: Frequency
    var nextDebitDate: Date
    var category: Category
    var isActive: Bool
    var merchant: String?
    var lastDebitDate: Date?
    var bankAccount: String?
    var createdAt: Date
    var cancelledAt: Date?
    var isCancelled: Bool { cancelledAt != nil }
    var syncToCalendar: Bool
    var calendarEventId: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        currency: String = "₹",
        frequency: Frequency,
        nextDebitDate: Date,
        category: Category,
        isActive: Bool = true,
        merchant: String? = nil,
        lastDebitDate: Date? = nil,
        bankAccount: String? = nil,
        createdAt: Date = Date(),
        cancelledAt: Date? = nil,
        syncToCalendar: Bool = false,
        calendarEventId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.currency = currency
        self.frequency = frequency
        self.nextDebitDate = nextDebitDate
        self.category = category
        self.isActive = isActive
        self.merchant = merchant
        self.lastDebitDate = lastDebitDate
        self.bankAccount = bankAccount
        self.createdAt = createdAt
        self.cancelledAt = cancelledAt
        self.syncToCalendar = syncToCalendar
        self.calendarEventId = calendarEventId
    }
    
    var daysUntilDebit: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextDebitDate).day ?? 0
    }
    
    var formattedAmount: String {
        "\(currency)\(String(format: "%.2f", amount))"
    }
}

enum Frequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biWeekly = "Bi-Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    case custom = "Custom"
    
    var days: Int {
        switch self {
        case .weekly: return 7
        case .biWeekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .yearly: return 365
        case .custom: return 30
        }
    }
}

enum Category: String, Codable, CaseIterable {
    case ott = "OTT/Streaming"
    case gym = "Gym/Fitness"
    case app = "App Subscription"
    case utility = "Utility"
    case music = "Music"
    case cloud = "Cloud Storage"
    case news = "News/Magazine"
    case software = "Software"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .ott: return "tv.fill"
        case .gym: return "figure.run"
        case .app: return "app.fill"
        case .utility: return "bolt.fill"
        case .music: return "music.note"
        case .cloud: return "cloud.fill"
        case .news: return "newspaper.fill"
        case .software: return "laptopcomputer"
        case .other: return "square.grid.2x2.fill"
        }
    }
}

