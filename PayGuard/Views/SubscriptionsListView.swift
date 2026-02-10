//
//  SubscriptionsListView.swift
//  PayGuard
//
//  Created for PayGuard
//

import SwiftUI
import Combine

struct SubscriptionsListView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showingAddSubscription = false
    @State private var selectedSubscription: Subscription?
    
    var activeSubscriptions: [Subscription] {
        subscriptionService.activeSubscriptions.sorted { $0.nextDebitDate < $1.nextDebitDate }
    }
    
    var cancelledSubscriptions: [Subscription] {
        subscriptionService.subscriptions.filter { $0.isCancelled }.sorted { ($0.cancelledAt ?? Date()) > ($1.cancelledAt ?? Date()) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Stats Card
                        StatsCardView(
                            totalMonthly: subscriptionService.totalMonthlyRecurring,
                            activeCount: activeSubscriptions.count
                        )
                        
                        // Active Subscriptions
                        if !activeSubscriptions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderC(title: "Active Subscriptions", count: activeSubscriptions.count)
                                
                                ForEach(activeSubscriptions) { subscription in
                                    SubscriptionCard(subscription: subscription)
                                        .onTapGesture {
                                            selectedSubscription = subscription
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Cancelled Subscriptions
                        if !cancelledSubscriptions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderC(title: "Cancelled Subscriptions", count: cancelledSubscriptions.count)
                                
                                ForEach(cancelledSubscriptions) { subscription in
                                    SubscriptionCard(subscription: subscription)
                                        .onTapGesture {
                                            selectedSubscription = subscription
                                        }
                                        .opacity(0.7)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Empty State
                        if activeSubscriptions.isEmpty && cancelledSubscriptions.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "creditcard.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue.opacity(0.3))
                                
                                Text("No Subscriptions")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("Add your first subscription\nto start tracking")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(40)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSubscription = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddSubscription) {
                AddSubscriptionView()
            }
            .sheet(item: $selectedSubscription) { subscription in
                EditSubscriptionView(subscription: subscription)
            }
        }
    }
}

// MARK: - Supporting Views

struct StatsCardView: View {
    let totalMonthly: Double
    let activeCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("₹\(String(format: "%.0f", totalMonthly))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(activeCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
}

struct SectionHeaderC: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.blue)
                .cornerRadius(12)
        }
    }
}

struct SubscriptionCard: View {
    let subscription: Subscription
    
    var statusColor: Color {
        if subscription.isCancelled {
            return .gray
        } else if subscription.daysUntilDebit <= 3 {
            return .orange
        } else {
            return .blue
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Circle
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: subscription.category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(statusColor)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 6) {
                Text(subscription.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .strikethrough(subscription.isCancelled, color: .gray)
                
                HStack(spacing: 8) {
                    Text(subscription.category.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.secondary)
                        .cornerRadius(6)
                    
                    Text(subscription.frequency.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
                
                if subscription.isCancelled {
                    if let cancelledAt = subscription.cancelledAt {
                        Text("Cancelled on \(cancelledAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } else {
                    Text("Next: \(subscription.nextDebitDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Amount and Status
            VStack(alignment: .trailing, spacing: 4) {
                Text(subscription.formattedAmount)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !subscription.isCancelled {
                    Text("in \(subscription.daysUntilDebit)d")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(statusColor.opacity(0.1))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    SubscriptionsListView()
}
