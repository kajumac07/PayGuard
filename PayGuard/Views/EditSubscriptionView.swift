//
//  EditSubscriptionView.swift
//  PayGuard
//
//  Created for PayGuard
//

import SwiftUI
import Combine
internal import EventKit

struct EditSubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var calendarService = CalendarService.shared
    
    let subscription: Subscription
    @State private var name: String
    @State private var amount: String
    @State private var selectedFrequency: Frequency
    @State private var selectedCategory: Category
    @State private var nextDebitDate: Date
    @State private var merchant: String
    @State private var syncToCalendar: Bool
    @State private var showingCalendarPermissionAlert = false
    
    init(subscription: Subscription) {
        self.subscription = subscription
        _name = State(initialValue: subscription.name)
        _amount = State(initialValue: String(format: "%.2f", subscription.amount))
        _selectedFrequency = State(initialValue: subscription.frequency)
        _selectedCategory = State(initialValue: subscription.category)
        _nextDebitDate = State(initialValue: subscription.nextDebitDate)
        _merchant = State(initialValue: subscription.merchant ?? "")
        _syncToCalendar = State(initialValue: subscription.syncToCalendar)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Subscription Details") {
                    TextField("Name", text: $name)
                    TextField("Amount (₹)", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section("Payment Frequency") {
                    Picker("Frequency", selection: $selectedFrequency) {
                        ForEach(Frequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon).tag(category)
                        }
                    }
                }
                
                Section("Next Debit Date") {
                    DatePicker("Next Debit", selection: $nextDebitDate, displayedComponents: .date)
                }
                
                Section("Merchant (Optional)") {
                    TextField("Merchant/Bank", text: $merchant)
                }
                
                Section("Calendar Sync") {
                    Toggle("Sync to Calendar", isOn: $syncToCalendar)
                        .onChange(of: syncToCalendar) { oldValue, newValue in
                            if newValue && !calendarService.hasEventAccess {
                                requestCalendarAccess()
                            }
                        }
                    
                    if syncToCalendar {
                        Text("Renewal date will be added to your calendar with a reminder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if subscription.isCancelled {
                    Section("Status") {
                        HStack {
                            Text("Cancelled")
                            Spacer()
                            if let cancelledAt = subscription.cancelledAt {
                                Text(cancelledAt.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    Section {
                        Button(role: .destructive) {
                            subscriptionService.cancelSubscription(subscription)
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Cancel Subscription")
                                Spacer()
                            }
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        subscriptionService.deleteSubscription(subscription)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Subscription")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Calendar Access Required", isPresented: $showingCalendarPermissionAlert) {
                Button("Cancel", role: .cancel) {
                    syncToCalendar = false
                }
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Please enable calendar access in Settings to sync subscription renewals.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSubscription()
                    }
                    .disabled(name.isEmpty || amount.isEmpty || Double(amount) == nil)
                }
            }
        }
    }
    
    private func saveSubscription() {
        guard let amountValue = Double(amount) else { return }
        
        let updated = Subscription(
            id: subscription.id,
            name: name,
            amount: amountValue,
            currency: subscription.currency,
            frequency: selectedFrequency,
            nextDebitDate: nextDebitDate,
            category: selectedCategory,
            isActive: subscription.isActive,
            merchant: merchant.isEmpty ? nil : merchant,
            lastDebitDate: subscription.lastDebitDate,
            bankAccount: subscription.bankAccount,
            createdAt: subscription.createdAt,
            cancelledAt: subscription.cancelledAt,
            syncToCalendar: syncToCalendar,
            calendarEventId: subscription.calendarEventId
        )
        
        subscriptionService.updateSubscription(updated)
        dismiss()
    }
    
    private func requestCalendarAccess() {
        Task {
            let granted = await calendarService.requestCalendarAccess()
            if !granted {
                await MainActor.run {
                    showingCalendarPermissionAlert = true
                }
            }
        }
    }
}

#Preview {
    EditSubscriptionView(subscription: Subscription(
        name: "Netflix",
        amount: 499,
        frequency: .monthly,
        nextDebitDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
        category: .ott
    ))
}

