//
//  Transaction.swift
//  PayGuard
//
//  Created for PayGuard
//

import Foundation

struct Transaction: Identifiable, Codable {
    let id: UUID
    let amount: Double
    let currency: String
    let merchant: String?
    let date: Date
    let description: String
    let bankAccount: String?
    let subscriptionId: UUID?
    let isSubscription: Bool
    
    init(
        id: UUID = UUID(),
        amount: Double,
        currency: String = "₹",
        merchant: String? = nil,
        date: Date,
        description: String,
        bankAccount: String? = nil,
        subscriptionId: UUID? = nil,
        isSubscription: Bool = false
    ) {
        self.id = id
        self.amount = amount
        self.currency = currency
        self.merchant = merchant
        self.date = date
        self.description = description
        self.bankAccount = bankAccount
        self.subscriptionId = subscriptionId
        self.isSubscription = isSubscription
    }
    
    var formattedAmount: String {
        "\(currency)\(String(format: "%.2f", amount))"
    }
}

