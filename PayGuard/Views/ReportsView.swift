//
//  ReportsView.swift
//  PayGuard
//
//  Created for PayGuard
//

import SwiftUI
import Combine

struct ReportsView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedMonth = Date()
    
    var monthlyWaste: Double {
        subscriptionService.getMonthlyWaste(for: selectedMonth)
    }
    
    var monthlySpending: Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        return subscriptionService.transactions
            .filter { $0.date >= startOfMonth && $0.date < endOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    var activeSubscriptionsCount: Int {
        subscriptionService.activeSubscriptions.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Month Selector
                    Section {
                        DatePicker("Select Month", selection: $selectedMonth, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // Monthly Waste Report
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Monthly Waste Report")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        WasteReportCard(
                            title: "Wasted This Month",
                            amount: monthlyWaste,
                            subtitle: "From cancelled subscriptions",
                            color: .red
                        )
                        
                        SpendingReportCard(
                            title: "Total Spending",
                            amount: monthlySpending,
                            subtitle: "All transactions this month",
                            color: .blue
                        )
                        
                        ActiveSubscriptionsCard(
                            count: activeSubscriptionsCount,
                            totalMonthly: subscriptionService.totalMonthlyRecurring
                        )
                    }
                    .padding(.top)
                    
                    // Category Breakdown
                    if !subscriptionService.activeSubscriptions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Spending by Category")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            CategoryBreakdownView()
                                .padding(.horizontal)
                        }
                        .padding(.top)
                    }
                    
                    // Recent Cancelled Subscriptions
                    let cancelledThisMonth = subscriptionService.subscriptions
                        .filter { sub in
                            guard let cancelledAt = sub.cancelledAt else { return false }
                            let calendar = Calendar.current
                            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
                            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
                            return cancelledAt >= startOfMonth && cancelledAt < endOfMonth
                        }
                    
                    if !cancelledThisMonth.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cancelled This Month")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(cancelledThisMonth) { subscription in
                                CancelledSubscriptionRow(subscription: subscription)
                            }
                        }
                        .padding(.top)
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Reports")
        }
    }
}

struct WasteReportCard: View {
    let title: String
    let amount: Double
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("₹\(String(format: "%.0f", amount))")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct SpendingReportCard: View {
    let title: String
    let amount: Double
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("₹\(String(format: "%.0f", amount))")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ActiveSubscriptionsCard: View {
    let count: Int
    let totalMonthly: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Active Subscriptions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(count)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Text("Monthly Total")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("₹\(String(format: "%.0f", totalMonthly))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct CategoryBreakdownView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    var categoryTotals: [(Category, Double)] {
        let grouped = Dictionary(grouping: subscriptionService.activeSubscriptions) { $0.category }
        return grouped.map { (category, subs) in
            (category, subs.reduce(0) { $0 + $1.amount })
        }.sorted { $0.1 > $1.1 }
    }
    
    var total: Double {
        categoryTotals.reduce(0) { $0 + $1.1 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(categoryTotals, id: \.0) { category, amount in
                HStack {
                    Image(systemName: category.icon)
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text(category.rawValue)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("₹\(String(format: "%.0f", amount))")
                            .font(.headline)
                        
                        let percentage = total > 0 ? (amount / total * 100) : 0
                        Text("\(String(format: "%.0f", percentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: total > 0 ? geometry.size.width * CGFloat(amount / total) : 0, height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct CancelledSubscriptionRow: View {
    let subscription: Subscription
    
    var body: some View {
        HStack {
            Image(systemName: subscription.category.icon)
                .font(.system(size: 20))
                .foregroundColor(.red)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .strikethrough()
                
                if let cancelledAt = subscription.cancelledAt {
                    Text("Cancelled: \(cancelledAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("₹\(String(format: "%.0f", subscription.amount))")
                .font(.headline)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    ReportsView()
}

