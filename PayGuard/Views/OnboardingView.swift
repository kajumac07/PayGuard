//
//  OnboardingView.swift
//  PayGuard
//
//  Created for PayGuard
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Stop Losing Money Every Month",
            description: "People waste ₹1,000+ monthly on subscriptions they forgot. You're probably losing money right now.",
            imageName: "indianrupeesign.circle.fill",
            color: .red
        ),
        OnboardingPage(
            title: "Get Alerted Before You're Charged",
            description: "We warn you 2-3 days before money is debited, so you can cancel and save before it's too late.",
            imageName: "bell.badge.fill",
            color: .orange
        ),
        OnboardingPage(
            title: "See Your Real Savings",
            description: "Track exactly how much you waste each month. Users typically save ₹1,200+ monthly by canceling unused subscriptions.",
            imageName: "chart.line.uptrend.xyaxis",
            color: .green
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [pages[currentPage].color.opacity(0.1), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.secondary)
                    .padding()
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Bottom buttons
                VStack(spacing: 16) {
                    // Page indicators (custom)
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? pages[currentPage].color : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut, value: currentPage)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Action button
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text("Next")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(pages[currentPage].color)
                                .cornerRadius(12)
                        }
                    } else {
                        Button(action: {
                            completeOnboarding()
                        }) {
                            HStack {
                                Text("Start Saving Money")
                                    .font(.headline)
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(pages[currentPage].color)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon/Image
            Image(systemName: page.imageName)
                .font(.system(size: 100))
                .foregroundColor(page.color)
                .padding(.bottom, 20)
            
            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.horizontal, 32)
            
            // Description
            Text(page.description)
                .font(.system(size: 17))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
                .lineSpacing(4)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
