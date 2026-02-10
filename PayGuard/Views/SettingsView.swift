//
//  SettingsView.swift
//  PayGuard
//
//  Created for PayGuard
//

import SwiftUI
import Combine
import UserNotifications

struct SettingsView: View {
    @StateObject private var smsService = SMSService.shared
    @StateObject private var calendarService = CalendarService.shared
    @StateObject private var gmailService = GmailService.shared
    @State private var notificationEnabled = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var showingCalendarPermissionAlert = false
    @State private var showingGmailReview = false
    @State private var showingGmailError = false
    @State private var gmailErrorMessage = ""
    @State private var showingManualEmailEntry = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            Text("Notifications")
                                .font(.headline)
                        }
                        
                        Text("Get alerted 2-3 days before your subscriptions are debited")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Enable Notifications") {
                            requestNotificationPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(notificationEnabled)
                        
                        if notificationEnabled {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Notifications enabled")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "text.bubble.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            
                            Text("SMS Reading")
                                .font(.headline)
                        }
                        
                        Text("iOS restricts direct SMS reading. To use SMS detection:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Manually paste SMS text in 'Add from SMS'")
                            Text("2. Use Shortcuts app to forward SMS to PayGuard")
                            Text("3. Check your bank's email alerts and copy from there")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        if !smsService.hasPermission {
                            Text("Permission not available (iOS restriction)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            Text("Calendar Sync")
                                .font(.headline)
                        }
                        
                        Text("Add subscription renewal dates to your calendar with reminders")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if calendarService.hasEventAccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Calendar access enabled")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Reminder Days Before Renewal")
                                    .font(.subheadline)
                                
                                Stepper("\(calendarService.reminderDaysBefore) day\(calendarService.reminderDaysBefore == 1 ? "" : "s")", value: Binding(
                                    get: { calendarService.reminderDaysBefore },
                                    set: { calendarService.setReminderDays($0) }
                                ), in: 1...30)
                            }
                            .padding(.top, 4)
                        } else {
                            Button("Enable Calendar Access") {
                                requestCalendarAccess()
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Text("Calendar access is required to sync renewal dates")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                            
                            Text("Gmail Sync")
                                .font(.headline)
                        }
                        
                        Text("Scan your Gmail for subscription receipts and renewals")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if gmailService.isConnected {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Gmail connected")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            Button(action: {
                                scanGmail()
                            }) {
                                HStack {
                                    if gmailService.isScanning {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "magnifyingglass")
                                    }
                                    Text(gmailService.isScanning ? "Scanning..." : "Scan Emails")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(gmailService.isScanning)
                            
                            Button("Disconnect Gmail") {
                                gmailService.disconnectGmail()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            Text("Manual Entry (for testing)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Add Email Manually") {
                                showingManualEmailEntry = true
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button("Connect Gmail") {
                                connectGmail()
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Text("Gmail sync requires OAuth connection. You'll be asked to grant read-only access to your emails.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let error = gmailService.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("App Name")
                        Spacer()
                        Text("PayGuard")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How PayGuard Works")
                            .font(.headline)
                        
                        Text("""
                        • Tracks all your subscriptions and auto-debits
                        • Alerts you 2-3 days before money is deducted
                        • Helps you cancel unused subscriptions on time
                        • Shows monthly waste report from cancelled subscriptions
                        • Provides insights into your spending patterns
                        """)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button(role: .destructive) {
                        clearAllData()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Clear All Data")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                checkNotificationStatus()
                calendarService.checkAuthorizationStatus()
            }
            .alert("Calendar Access Required", isPresented: $showingCalendarPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Please enable calendar access in Settings to sync subscription renewals.")
            }
            .alert("Permission Required", isPresented: $showingPermissionAlert) {
                Button("OK", role: .cancel) { }
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text(permissionAlertMessage)
            }
            .alert("Gmail Error", isPresented: $showingGmailError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(gmailErrorMessage)
            }
            .sheet(isPresented: $showingGmailReview) {
                GmailReviewView()
            }
            .sheet(isPresented: $showingManualEmailEntry) {
                ManualEmailEntryView()
            }
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    notificationEnabled = true
                    SubscriptionService.shared.scheduleNotifications()
                } else {
                    permissionAlertMessage = "Please enable notifications in Settings to get alerts before debits."
                    showingPermissionAlert = true
                }
                
                if let error = error {
                    permissionAlertMessage = "Error: \(error.localizedDescription)"
                    showingPermissionAlert = true
                }
            }
        }
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
    
    private func connectGmail() {
        Task {
            do {
                try await gmailService.connectGmail()
            } catch {
                await MainActor.run {
                    gmailErrorMessage = error.localizedDescription
                    showingGmailError = true
                }
            }
        }
    }
    
    private func scanGmail() {
        Task {
            do {
                try await gmailService.scanEmails()
                await MainActor.run {
                    if !gmailService.scannedEmails.isEmpty {
                        showingGmailReview = true
                    }
                }
            } catch {
                await MainActor.run {
                    gmailErrorMessage = error.localizedDescription
                    showingGmailError = true
                }
            }
        }
    }
    
    private func clearAllData() {
        // Clear all subscriptions and transactions
        SubscriptionService.shared.subscriptions.removeAll()
        SubscriptionService.shared.transactions.removeAll()
        UserDefaults.standard.removeObject(forKey: "savedSubscriptions")
        UserDefaults.standard.removeObject(forKey: "savedTransactions")
    }
}

#Preview {
    SettingsView()
}

