//
//  DashboardView.swift
//  PayGuard
//
//  Created for PayGuard
//

import SwiftUI

struct DashboardView: View {
    @State private var subscriptionService = SubscriptionService.shared
    @State private var showingAddSubscription = false
    @State private var showingAddTransaction = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Overview Tab
                OverviewTabView()
                    .tabItem {
                        Label("Overview", systemImage: "chart.bar.fill")
                    }
                    .tag(0)
                
                // Subscriptions Tab
                SubscriptionsListView()
                    .tabItem {
                        Label("Subscriptions", systemImage: "creditcard.fill")
                    }
                    .tag(1)
                
                // Reports Tab
                ReportsView()
                    .tabItem {
                        Label("Reports", systemImage: "doc.text.fill")
                    }
                    .tag(2)
                
                // Settings Tab
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
        }
    }
}

struct OverviewTabView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showingAddSubscription = false
    @State private var showingAddTransaction = false
    @State private var selectedTimeFrame: TimeFrame = .monthly
    
    enum TimeFrame: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
    
    // Compute current month's spending from transactions
    private var monthlySpending: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        return subscriptionService.transactions
            .filter { $0.date >= startOfMonth && $0.date < endOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        // Compute once for the whole view
        let upcomingDebits = subscriptionService.getUpcomingDebits(daysAhead: 7)
        let totalMonthly = subscriptionService.totalMonthlyRecurring
        
        ScrollView {
            VStack(spacing: 24) {
                // Header with time frame selector
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back!")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Overview")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        // Time frame selector
                        Picker("Time Frame", selection: $selectedTimeFrame) {
                            ForEach(TimeFrame.allCases, id: \.self) { frame in
                                Text(frame.rawValue)
                                    .tag(frame)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    .padding(.horizontal)
                    
                    // Summary card
                    SummaryCardView(
                        totalAmount: totalMonthly,
                        activeCount: subscriptionService.activeSubscriptions.count,
                        upcomingCount: upcomingDebits.count,
                        timeFrame: selectedTimeFrame
                    )
                }
                .padding(.top, 8)
                
                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    StatCard(
                        title: "Monthly Total",
                        value: "₹\(String(format: "%.0f", totalMonthly))",
                        subtitle: selectedTimeFrame.rawValue,
                        icon: "indianrupeesign.circle.fill",
                        iconColor: .blue,
                        gradient: LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    StatCard(
                        title: "Active Subs",
                        value: "\(subscriptionService.activeSubscriptions.count)",
                        subtitle: "Ongoing",
                        icon: "checkmark.circle.fill",
                        iconColor: .green,
                        gradient: LinearGradient(
                            colors: [.green, .green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    StatCard(
                        title: "Upcoming",
                        value: "\(upcomingDebits.count)",
                        subtitle: "Next 7 days",
                        icon: "calendar.badge.clock",
                        iconColor: .orange,
                        gradient: LinearGradient(
                            colors: [.orange, .orange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    StatCard(
                        title: "This Month",
                        value: "₹\(String(format: "%.0f", monthlySpending))",
                        subtitle: "Spent",
                        icon: "arrow.down.circle.fill",
                        iconColor: .purple,
                        gradient: LinearGradient(
                            colors: [.purple, .purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
                .padding(.horizontal)
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        QuickActionButton(
                            title: "Add Subscription",
                            icon: "plus.circle.fill",
                            color: .blue,
                            action: { showingAddSubscription = true }
                        )
                        
                        QuickActionButton(
                            title: "Scan SMS",
                            icon: "text.bubble.fill",
                            color: .green,
                            action: { showingAddTransaction = true }
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)
                
                // Upcoming Debits Section
                if !upcomingDebits.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            title: "Upcoming Debits",
                            count: upcomingDebits.count,
                            icon: "calendar.badge.exclamationmark",
                            color: .orange
                        )
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(upcomingDebits.prefix(5)) { subscription in
                                    UpcomingDebitCard(subscription: subscription)
                                        .frame(width: 280)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                }
                
                // Recent Transactions
                if !subscriptionService.transactions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            title: "Recent Transactions",
                            count: subscriptionService.transactions.count,
                            icon: "list.bullet.rectangle.fill",
                            color: .blue
                        )
                        
                        VStack(spacing: 12) {
                            ForEach(subscriptionService.transactions.suffix(5).reversed()) { transaction in
                                TransactionCard(transaction: transaction)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                }
                
                // Empty state if no data
                if subscriptionService.activeSubscriptions.isEmpty && subscriptionService.transactions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "creditcard.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue.opacity(0.3))
                        
                        Text("No Subscriptions Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Add your first subscription to start tracking")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showingAddSubscription = true }) {
                            Label("Add Subscription", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding(40)
                }
            }
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddSubscription) {
            AddSubscriptionView()
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
        }
    }
}

// MARK: - Supporting Views

struct SummaryCardView: View {
    let totalAmount: Double
    let activeCount: Int
    let upcomingCount: Int
    let timeFrame: OverviewTabView.TimeFrame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total \(timeFrame.rawValue) Spend")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("₹\(String(format: "%.0f", totalAmount))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatPill(value: "\(activeCount)", label: "Active", color: .white)
                    StatPill(value: "\(upcomingCount)", label: "Upcoming", color: .white)
                }
            }
            
            ProgressBar(value: CGFloat(totalAmount) / 10000, color: .white)
                .frame(height: 8)
                .cornerRadius(4)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.blue.opacity(0.3), radius: 15, x: 0, y: 8)
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(gradient)
        .cornerRadius(16)
        // Use a fixed shadow color instead of gradient.stops
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
}

struct SectionHeader: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(color)
                .cornerRadius(12)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

struct UpcomingDebitCard: View {
    let subscription: Subscription
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: subscription.category.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Text(subscription.formattedAmount)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Text(subscription.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Label("Due in \(subscription.daysUntilDebit) day\(subscription.daysUntilDebit == 1 ? "" : "s")",
                      systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(subscription.frequency.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }
            
            Button(action: { subscriptionService.cancelSubscription(subscription) }) {
                Text("Cancel Subscription")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct TransactionCard: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(transaction.isSubscription ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: transaction.isSubscription ? "arrow.down.circle.fill" : "arrow.right.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(transaction.isSubscription ? .red : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant ?? "Unknown")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.formattedAmount)
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text("Debited")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

struct ProgressBar: View {
    let value: CGFloat
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: geometry.size.width)
                
                Rectangle()
                    .fill(color)
                    .frame(width: min(value * geometry.size.width, geometry.size.width))
            }
        }
    }
}

struct StatPill: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.2))
        .cornerRadius(8)
    }
}
#Preview {
    DashboardView()
}
