//
//  StatsCardView.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import SwiftUI

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
                
                // Optional trend indicator
                if shouldShowTrend {
                    trendIndicator
                }
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(value)
                    .font(AppFonts.title)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
    
    private var shouldShowTrend: Bool {
        // Show trend for numeric values
        return value.contains("%") || Int(value) != nil
    }
    
    private var trendIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.up.right")
                .font(.caption2)
                .foregroundColor(AppColors.success)
            
            Text("+12%")
                .font(.caption2)
                .foregroundColor(AppColors.success)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(AppColors.success.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Brief Card
struct BriefCard: View {
    let brief: AgentBrief
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(AppColors.secondary)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Daily Brief")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(brief.briefDate)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            
            Text(brief.summary)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(3)
            
            if !brief.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Action Items:")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textPrimary)
                    
                    ForEach(brief.actionItems.prefix(3)) { item in
                        HStack(spacing: AppSpacing.xs) {
                            Circle()
                                .fill(item.priority == "high" ? AppColors.danger : AppColors.warning)
                                .frame(width: 4, height: 4)
                            
                            Text(item.title)
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: [Color]
    let action: () async -> Void
    
    @State private var isLoading = false
    
    var body: some View {
        Button(action: {
            Task {
                isLoading = true
                HapticManager.impact(.light)
                await action()
                isLoading = false
            }
        }) {
            VStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: color,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: icon)
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                
                Text(title)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 120)
            .cardStyle()
        }
        .disabled(isLoading)
    }
}

// MARK: - Badge
struct Badge: View {
    let count: Int
    let color: Color
    
    var body: some View {
        Text("\(count)")
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColors.cardBackground, lineWidth: 2)
            )
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(AppColors.textSecondary)
            
            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(message)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppSpacing.xl)
        .cardStyle()
    }
}

#Preview {
    VStack(spacing: 16) {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatsCard(
                title: "New Leads",
                value: "12",
                icon: "person.crop.circle.badge.plus",
                color: AppColors.primary
            )
            
            StatsCard(
                title: "Engagement Rate",
                value: "4.2%",
                icon: "heart.fill",
                color: AppColors.secondary
            )
        }
        
        BriefCard(
            brief: AgentBrief(
                id: "1",
                userId: "user1",
                briefType: "morning",
                briefDate: "November 4, 2025",
                summary: "Good morning! Your Scout Agent found 3 new wedding leads in NYC, and your Marketing Agent scheduled 2 posts for today.",
                actionItems: [
                    ActionItem(id: "1", title: "Review wedding lead from The Plaza", description: "", priority: "high", completed: false),
                    ActionItem(id: "2", title: "Approve Instagram caption", description: "", priority: "medium", completed: false)
                ],
                createdAt: Date()
            )
        )
    }
    .padding()
    .background(AppColors.background)
}