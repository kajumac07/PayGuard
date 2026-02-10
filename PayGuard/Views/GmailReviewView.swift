//
//  GmailReviewView.swift
//  PayGuard
//
//  Created for PayGuard
//

import SwiftUI

struct GmailReviewView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var gmailService = GmailService.shared
    
    @State private var selectedSubscriptions: Set<UUID> = []
    @State private var editedSubscriptions: [UUID: ParsedEmailSubscription] = [:]
    @State private var showingEditSheet: Bool = false
    @State private var editingSubscription: ParsedEmailSubscription?
    
    var body: some View {
        NavigationStack {
            if gmailService.scannedEmails.isEmpty {
                ContentUnavailableView {
                    Label("No Subscriptions Found", systemImage: "envelope")
                } description: {
                    Text("No subscription-related emails were found in your Gmail account.")
                }
            } else {
                List {
                    ForEach(gmailService.scannedEmails) { parsed in
                        SubscriptionReviewRow(
                            parsed: parsed,
                            isSelected: selectedSubscriptions.contains(parsed.id),
                            editedVersion: editedSubscriptions[parsed.id]
                        ) {
                            if selectedSubscriptions.contains(parsed.id) {
                                selectedSubscriptions.remove(parsed.id)
                            } else {
                                selectedSubscriptions.insert(parsed.id)
                            }
                        } onEdit: {
                            editingSubscription = parsed
                            showingEditSheet = true
                        }
                    }
                }
                .navigationTitle("Review & Confirm")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            gmailService.scannedEmails.removeAll()
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save Selected") {
                            saveSelectedSubscriptions()
                        }
                        .disabled(selectedSubscriptions.isEmpty)
                    }
                }
                .sheet(isPresented: $showingEditSheet) {
                    if let parsed = editingSubscription {
                        EditParsedSubscriptionView(
                            parsed: editedSubscriptions[parsed.id] ?? parsed,
                            onSave: { edited in
                                editedSubscriptions[parsed.id] = edited
                                showingEditSheet = false
                                editingSubscription = nil
                            },
                            onCancel: {
                                showingEditSheet = false
                                editingSubscription = nil
                            }
                        )
                    }
                }
            }
        }
    }
    
    private func saveSelectedSubscriptions() {
        for id in selectedSubscriptions {
            guard let parsed = gmailService.scannedEmails.first(where: { $0.id == id }) else { continue }
            
            let edited = editedSubscriptions[id] ?? parsed
            
            // Check if subscription already exists
            let existing = subscriptionService.subscriptions.first { sub in
                sub.name.lowercased() == edited.serviceName.lowercased() && sub.isActive
            }
            
            if let existing = existing {
                // Update existing subscription
                let updated = Subscription(
                    id: existing.id,
                    name: edited.serviceName,
                    amount: edited.amount,
                    currency: edited.currency,
                    frequency: edited.frequency,
                    nextDebitDate: edited.nextDebitDate,
                    category: determineCategory(from: edited.serviceName),
                    isActive: existing.isActive,
                    merchant: edited.serviceName,
                    lastDebitDate: edited.date,
                    bankAccount: existing.bankAccount,
                    createdAt: existing.createdAt,
                    cancelledAt: existing.cancelledAt,
                    syncToCalendar: existing.syncToCalendar,
                    calendarEventId: existing.calendarEventId
                )
                subscriptionService.updateSubscription(updated)
            } else {
                // Create new subscription
                let subscription = Subscription(
                    name: edited.serviceName,
                    amount: edited.amount,
                    currency: edited.currency,
                    frequency: edited.frequency,
                    nextDebitDate: edited.nextDebitDate,
                    category: determineCategory(from: edited.serviceName),
                    merchant: edited.serviceName,
                    lastDebitDate: edited.date
                )
                subscriptionService.addSubscription(subscription)
            }
            
            // Also add as transaction
            let transaction = Transaction(
                amount: edited.amount,
                currency: edited.currency,
                merchant: edited.serviceName,
                date: edited.date,
                description: edited.emailSubject ?? "Gmail import",
                isSubscription: true
            )
            subscriptionService.addTransaction(transaction)
        }
        
        gmailService.scannedEmails.removeAll()
        dismiss()
    }
    
    private func determineCategory(from serviceName: String) -> Category {
        let name = serviceName.lowercased()
        if name.contains("netflix") || name.contains("prime") || name.contains("disney") || name.contains("hotstar") || name.contains("ott") {
            return .ott
        } else if name.contains("gym") || name.contains("fitness") {
            return .gym
        } else if name.contains("spotify") || name.contains("music") {
            return .music
        } else if name.contains("dropbox") || name.contains("icloud") || name.contains("cloud") {
            return .cloud
        } else if name.contains("app") || name.contains("software") {
            return .app
        } else {
            return .other
        }
    }
}

struct SubscriptionReviewRow: View {
    let parsed: ParsedEmailSubscription
    let isSelected: Bool
    let editedVersion: ParsedEmailSubscription?
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    var displayParsed: ParsedEmailSubscription {
        editedVersion ?? parsed
    }
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(displayParsed.serviceName)
                        .font(.headline)
                    
                    if editedVersion != nil {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                HStack(spacing: 16) {
                    Label(displayParsed.formattedAmount, systemImage: "indianrupeesign.circle")
                        .font(.subheadline)
                    
                    Label(displayParsed.frequency.rawValue, systemImage: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let subject = displayParsed.emailSubject {
                    Text(subject)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text("Next debit: \(displayParsed.nextDebitDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EditParsedSubscriptionView: View {
    @State var parsed: ParsedEmailSubscription
    let onSave: (ParsedEmailSubscription) -> Void
    let onCancel: () -> Void
    
    @State private var serviceName: String
    @State private var amount: String
    @State private var selectedFrequency: Frequency
    @State private var nextDebitDate: Date
    
    init(parsed: ParsedEmailSubscription, onSave: @escaping (ParsedEmailSubscription) -> Void, onCancel: @escaping () -> Void) {
        self.parsed = parsed
        self.onSave = onSave
        self.onCancel = onCancel
        _serviceName = State(initialValue: parsed.serviceName)
        _amount = State(initialValue: String(format: "%.2f", parsed.amount))
        _selectedFrequency = State(initialValue: parsed.frequency)
        _nextDebitDate = State(initialValue: parsed.nextDebitDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Service Name") {
                    TextField("Service Name", text: $serviceName)
                }
                
                Section("Amount") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section("Frequency") {
                    Picker("Frequency", selection: $selectedFrequency) {
                        ForEach(Frequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }
                
                Section("Next Debit Date") {
                    DatePicker("Next Debit", selection: $nextDebitDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(serviceName.isEmpty || amount.isEmpty || Double(amount) == nil)
                }
            }
        }
    }
    
    private func save() {
        guard let amountValue = Double(amount) else { return }
        
        var updated = parsed
        updated.serviceName = serviceName
        updated.amount = amountValue
        updated.frequency = selectedFrequency
        updated.nextDebitDate = nextDebitDate
        
        onSave(updated)
    }
}

#Preview {
    GmailReviewView()
}
