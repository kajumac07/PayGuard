//
//  SubscriptionService.swift
//  PayGuard
//
//  Created for PayGuard
//

import Foundation
import UserNotifications
import Combine

@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var subscriptions: [Subscription] = []
    @Published var transactions: [Transaction] = []
    
    private let userDefaults = UserDefaults.standard
    private let subscriptionsKey = "savedSubscriptions"
    private let transactionsKey = "savedTransactions"
    private let calendarService = CalendarService.shared
    
    private init() {
        loadSubscriptions()
        loadTransactions()
        scheduleNotifications()
    }
    
    // MARK: - Subscription Management
    
    func addSubscription(_ subscription: Subscription) {
        subscriptions.append(subscription)
        saveSubscriptions()
        scheduleNotification(for: subscription)
        syncCalendarEvent(for: subscription)
    }
    
    func updateSubscription(_ subscription: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = subscription
            saveSubscriptions()
            scheduleNotification(for: subscription)
            syncCalendarEvent(for: subscription)
        }
    }
    
    func deleteSubscription(_ subscription: Subscription) {
        // Delete calendar event if exists
        if let eventId = subscription.calendarEventId {
            Task {
                try? await calendarService.deleteEvent(eventId: eventId)
            }
        }
        subscriptions.removeAll { $0.id == subscription.id }
        saveSubscriptions()
        cancelNotification(for: subscription)
    }
    
    func cancelSubscription(_ subscription: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            let original = subscriptions[index]
            let cancelled = Subscription(
                id: original.id,
                name: original.name,
                amount: original.amount,
                currency: original.currency,
                frequency: original.frequency,
                nextDebitDate: original.nextDebitDate,
                category: original.category,
                isActive: false,
                merchant: original.merchant,
                lastDebitDate: original.lastDebitDate,
                bankAccount: original.bankAccount,
                createdAt: original.createdAt,
                cancelledAt: Date(),
                syncToCalendar: original.syncToCalendar,
                calendarEventId: original.calendarEventId
            )
            subscriptions[index] = cancelled
            saveSubscriptions()
            cancelNotification(for: cancelled)
            // Remove calendar event when cancelled
            syncCalendarEvent(for: cancelled)
        }
    }
    
    var activeSubscriptions: [Subscription] {
        subscriptions.filter { $0.isActive && !$0.isCancelled }
    }
    
    var totalMonthlyRecurring: Double {
        activeSubscriptions
            .filter { $0.frequency == .monthly || $0.frequency == .weekly || $0.frequency == .biWeekly }
            .reduce(0) { total, sub in
                let monthlyAmount: Double
                switch sub.frequency {
                case .weekly:
                    monthlyAmount = sub.amount * 4.33 // Average weeks per month
                case .biWeekly:
                    monthlyAmount = sub.amount * 2.17 // Average bi-weeks per month
                case .monthly:
                    monthlyAmount = sub.amount
                default:
                    monthlyAmount = sub.amount / 12 // For yearly, divide by 12
                }
                return total + monthlyAmount
            }
    }
    
    // MARK: - Transaction Management
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        saveTransactions()
        
        // If this is a subscription transaction, update the subscription
        if let subscriptionId = transaction.subscriptionId,
           let subscription = subscriptions.first(where: { $0.id == subscriptionId }) {
            var updated = subscription
            updated.lastDebitDate = transaction.date
            updated.nextDebitDate = Calendar.current.date(byAdding: .day, value: subscription.frequency.days, to: transaction.date) ?? subscription.nextDebitDate
            updateSubscription(updated)
        }
    }
    
    func addParsedTransaction(_ parsed: ParsedTransaction, category: Category = .other) {
        let transaction = Transaction(
            amount: parsed.amount,
            merchant: parsed.merchant,
            date: parsed.date,
            description: parsed.description,
            isSubscription: parsed.isSubscription
        )
        addTransaction(transaction)
        
        // If it's a subscription, create or update subscription
        if parsed.isSubscription {
            if let merchant = parsed.merchant,
               let existing = subscriptions.first(where: { $0.name.lowercased() == merchant.lowercased() && $0.isActive }) {
                // Update existing subscription
                let updated = Subscription(
                    id: existing.id,
                    name: existing.name,
                    amount: existing.amount,
                    currency: existing.currency,
                    frequency: existing.frequency,
                    nextDebitDate: Calendar.current.date(byAdding: .day, value: existing.frequency.days, to: parsed.date) ?? existing.nextDebitDate,
                    category: existing.category,
                    isActive: existing.isActive,
                    merchant: existing.merchant,
                    lastDebitDate: parsed.date,
                    bankAccount: existing.bankAccount,
                    createdAt: existing.createdAt,
                    cancelledAt: existing.cancelledAt,
                    syncToCalendar: existing.syncToCalendar,
                    calendarEventId: existing.calendarEventId
                )
                updateSubscription(updated)
            } else {
                // Create new subscription
                let subscription = Subscription(
                    name: parsed.merchant ?? "Unknown Subscription",
                    amount: parsed.amount,
                    frequency: .monthly, // Default to monthly, user can change
                    nextDebitDate: Calendar.current.date(byAdding: .day, value: 30, to: parsed.date) ?? Date().addingTimeInterval(30 * 24 * 60 * 60),
                    category: category,
                    lastDebitDate: parsed.date
                )
                addSubscription(subscription)
            }
        }
    }
    
    // MARK: - Monthly Waste Report
    
    func getMonthlyWaste(for month: Date = Date()) -> Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        // Calculate waste from cancelled subscriptions that were active during the month
        let waste = subscriptions
            .filter { sub in
                guard let cancelledAt = sub.cancelledAt else { return false }
                return cancelledAt >= startOfMonth && cancelledAt < endOfMonth
            }
            .reduce(0.0) { $0 + $1.amount }
        
        return waste
    }
    
    // MARK: - Upcoming Debits
    
    func getUpcomingDebits(daysAhead: Int = 7) -> [Subscription] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: daysAhead, to: Date()) ?? Date()
        return activeSubscriptions
            .filter { $0.nextDebitDate <= cutoffDate && $0.nextDebitDate >= Date() }
            .sorted { $0.nextDebitDate < $1.nextDebitDate }
    }
    
    // MARK: - Notifications
    
    func scheduleNotifications() {
        // Cancel all existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule for each active subscription
        for subscription in activeSubscriptions {
            scheduleNotification(for: subscription)
        }
    }
    
    func scheduleNotification(for subscription: Subscription) {
        guard subscription.isActive && !subscription.isCancelled else { return }
        
        // Schedule notification 2-3 days before debit
        let notificationDate = Calendar.current.date(byAdding: .day, value: -2, to: subscription.nextDebitDate) ?? Date()
        
        // Only schedule if in the future
        guard notificationDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Debit Alert"
        content.body = "₹\(String(format: "%.0f", subscription.amount)) will be debited for \(subscription.name) in 2 days. You can cancel to avoid this charge."
        content.sound = .default
        content.badge = 1
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: subscription.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelNotification(for subscription: Subscription) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [subscription.id.uuidString])
    }
    
    // MARK: - Persistence
    
    private func saveSubscriptions() {
        if let encoded = try? JSONEncoder().encode(subscriptions) {
            userDefaults.set(encoded, forKey: subscriptionsKey)
        }
    }
    
    private func loadSubscriptions() {
        if let data = userDefaults.data(forKey: subscriptionsKey),
           let decoded = try? JSONDecoder().decode([Subscription].self, from: data) {
            subscriptions = decoded
        }
    }
    
    private func saveTransactions() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            userDefaults.set(encoded, forKey: transactionsKey)
        }
    }
    
    private func loadTransactions() {
        if let data = userDefaults.data(forKey: transactionsKey),
           let decoded = try? JSONDecoder().decode([Transaction].self, from: data) {
            transactions = decoded
        }
    }
    
    // MARK: - Calendar Sync
    
    private func syncCalendarEvent(for subscription: Subscription) {
        Task {
            do {
                let eventId = try await calendarService.createOrUpdateEvent(for: subscription)
                // Update subscription with calendar event ID if it changed
                if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
                    var updated = subscriptions[index]
                    updated.calendarEventId = eventId
                    subscriptions[index] = updated
                    saveSubscriptions()
                }
            } catch {
                print("Calendar sync error: \(error.localizedDescription)")
            }
        }
    }
}
