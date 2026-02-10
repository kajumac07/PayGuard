//
//  ManualEmailEntryView.swift
//  PayGuard
//
//  Created for PayGuard
//

import SwiftUI
import Combine

struct ManualEmailEntryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var gmailService = GmailService.shared
    @State private var emailSubject: String = ""
    @State private var emailContent: String = ""
    @State private var parsedSubscription: ParsedEmailSubscription?
    @State private var showingReview = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Email Subject") {
                    TextField("Enter email subject", text: $emailSubject)
                }
                
                Section("Email Content") {
                    TextEditor(text: $emailContent)
                        .frame(height: 200)
                }
                
                Section {
                    Button("Parse Email") {
                        parseEmail()
                    }
                    .disabled(emailSubject.isEmpty && emailContent.isEmpty)
                }
                
                if let parsed = parsedSubscription {
                    Section("Parsed Subscription") {
                        HStack {
                            Text("Service:")
                            Spacer()
                            Text(parsed.serviceName)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Amount:")
                            Spacer()
                            Text(parsed.formattedAmount)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Frequency:")
                            Spacer()
                            Text(parsed.frequency.rawValue)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Date:")
                            Spacer()
                            Text(parsed.date.formatted(date: .abbreviated, time: .omitted))
                                .fontWeight(.semibold)
                        }
                        
                        Button("Add to Review") {
                            gmailService.addManualEmail(parsed)
                            showingReview = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Manual Email Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingReview) {
                GmailReviewView()
            }
        }
    }
    
    private func parseEmail() {
        parsedSubscription = gmailService.parseManualEmail(
            subject: emailSubject,
            content: emailContent
        )
    }
}

#Preview {
    ManualEmailEntryView()
}
