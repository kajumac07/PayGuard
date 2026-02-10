//
//  AddSubscriptionView.swift
//  PayGuard
//
//  Created for PayGuard
//

import SwiftUI

struct AddSubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var calendarService = CalendarService.shared
    
    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var selectedFrequency: Frequency = .monthly
    @State private var selectedCategory: Category = .other
    @State private var nextDebitDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var merchant: String = ""
    @State private var syncToCalendar: Bool = false
    @State private var showingCalendarPermissionAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Subscription Details") {
                    TextField("Name (e.g., Netflix)", text: $name)
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
            }
            .navigationTitle("Add Subscription")
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
            .navigationBarTitleDisplayMode(.inline)
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
        
        let subscription = Subscription(
            name: name,
            amount: amountValue,
            frequency: selectedFrequency,
            nextDebitDate: nextDebitDate,
            category: selectedCategory,
            merchant: merchant.isEmpty ? nil : merchant,
            syncToCalendar: syncToCalendar
        )
        
        subscriptionService.addSubscription(subscription)
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
    AddSubscriptionView()
}

