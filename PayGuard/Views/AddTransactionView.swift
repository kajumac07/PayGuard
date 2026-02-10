//
//  AddTransactionView.swift
//  PayGuard
//
//  Created for PayGuard
//

import SwiftUI
import Combine

struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var smsService = SMSService.shared
    
    @State private var smsText: String = ""
    @State private var parsedTransaction: ParsedTransaction?
    @State private var selectedCategory: Category = .other
    @State private var showingParsedResult = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Paste SMS text below to auto-detect subscription details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("SMS Text") {
                    TextEditor(text: $smsText)
                        .frame(height: 150)
                }
                
                Section {
                    Button("Parse SMS") {
                        parseSMSText()
                    }
                    .disabled(smsText.isEmpty)
                }
                
                if let parsed = parsedTransaction {
                    Section("Parsed Details") {
                        HStack {
                            Text("Amount:")
                            Spacer()
                            Text("₹\(String(format: "%.2f", parsed.amount))")
                                .fontWeight(.semibold)
                        }
                        
                        if let merchant = parsed.merchant {
                            HStack {
                                Text("Merchant:")
                                Spacer()
                                Text(merchant)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        HStack {
                            Text("Is Subscription:")
                            Spacer()
                            Text(parsed.isSubscription ? "Yes" : "No")
                                .fontWeight(.semibold)
                                .foregroundColor(parsed.isSubscription ? .green : .gray)
                        }
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(Category.allCases, id: \.self) { category in
                                Label(category.rawValue, systemImage: category.icon).tag(category)
                            }
                        }
                    }
                    
                    Section {
                        Button("Add Transaction") {
                            addTransaction()
                        }
                        .disabled(smsText.isEmpty)
                    }
                }
                
                Section {
                    Button("Simulate Sample SMS") {
                        // Use first sample SMS for testing
                        if let sample = smsService.simulateSMSScan().first {
                            smsText = sample.description
                            parseSMSText()
                        }
                    }
                }
            }
            .navigationTitle("Add from SMS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func parseSMSText() {
        parsedTransaction = smsService.processSMSText(smsText)
    }
    
    private func addTransaction() {
        guard let parsed = parsedTransaction else { return }
        subscriptionService.addParsedTransaction(parsed, category: selectedCategory)
        dismiss()
    }
}

#Preview {
    AddTransactionView()
}

