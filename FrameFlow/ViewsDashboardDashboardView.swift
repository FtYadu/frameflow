//
//  DashboardView.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var authService = AuthService.shared
    @State private var showingNotifications = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.agents.isEmpty {
                    loadingView
                } else {
                    mainContent
                }
            }
            .navigationTitle("FrameFlow")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    notificationButton
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    profileButton
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .task {
                await viewModel.loadDashboardData()
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.lg) {
                // Stats Cards
                statsSection
                
                // Agent Cards
                agentsSection
                
                // Morning Brief
                if let brief = viewModel.morningBrief {
                    briefSection(brief: brief)
                }
                
                // Recent Activity
                recentActivitySection
                
                // Quick Actions
                quickActionsSection
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, 100) // Space for voice button
        }
        .overlay(alignment: .bottomTrailing) {
            voiceButton
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Overview")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppSpacing.md) {
                StatsCard(
                    title: "New Leads",
                    value: "\(viewModel.leadsCount)",
                    icon: "person.crop.circle.badge.plus",
                    color: AppColors.primary
                )
                
                StatsCard(
                    title: "Posts This Week",
                    value: "\(viewModel.postsThisWeek)",
                    icon: "chart.line.uptrend.xyaxis",
                    color: AppColors.success
                )
                
                StatsCard(
                    title: "Engagement Rate",
                    value: viewModel.engagementRate,
                    icon: "heart.fill",
                    color: AppColors.secondary
                )
                
                StatsCard(
                    title: "Monthly Revenue",
                    value: viewModel.monthlyRevenue,
                    icon: "dollarsign.circle.fill",
                    color: AppColors.warning
                )
            }
        }
    }
    
    // MARK: - Agents Section
    private var agentsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("AI Agents")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(viewModel.activeAgentsCount) Active")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppSpacing.md) {
                ForEach(viewModel.agents) { agent in
                    AgentCardView(
                        agent: agent,
                        onToggle: { await viewModel.toggleAgent(agent) },
                        onTrigger: { action in
                            if let agentType = agent.type {
                                await viewModel.triggerAgent(agentType, action: action)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Brief Section
    private func briefSection(brief: AgentBrief) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Morning Brief")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            BriefCard(brief: brief)
        }
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Recent Activity")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if viewModel.pendingTasksCount > 0 {
                    Badge(count: viewModel.pendingTasksCount, color: AppColors.warning)
                }
            }
            
            if viewModel.tasks.isEmpty {
                EmptyStateView(
                    icon: "clock",
                    title: "No Recent Activity",
                    message: "Your agents will show their work here"
                )
            } else {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.tasks.prefix(5)) { task in
                        TaskRowView(
                            task: task,
                            onApprove: { approved in
                                await viewModel.approveTask(task, approved: approved)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Quick Actions")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppSpacing.md) {
                QuickActionCard(
                    title: "Find Leads",
                    icon: "person.crop.circle.badge.plus",
                    color: AgentType.scout.gradientColors
                ) {
                    await viewModel.triggerAgent(.scout, action: "find_leads")
                }
                
                QuickActionCard(
                    title: "Generate Caption",
                    icon: "text.bubble",
                    color: AgentType.marketing.gradientColors
                ) {
                    await viewModel.triggerAgent(.marketing, action: "generate_caption")
                }
            }
        }
    }
    
    // MARK: - Supporting Views
    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                .scaleEffect(1.5)
            
            Text("Loading your dashboard...")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    private var notificationButton: some View {
        Button(action: {
            showingNotifications = true
        }) {
            ZStack {
                Image(systemName: "bell")
                    .font(.title2)
                    .foregroundColor(AppColors.textPrimary)
                
                if viewModel.unreadNotificationsCount > 0 {
                    Badge(count: viewModel.unreadNotificationsCount, color: AppColors.danger)
                        .offset(x: 12, y: -12)
                }
            }
        }
    }
    
    private var profileButton: some View {
        Button(action: {
            authService.logout()
        }) {
            Image(systemName: "person.circle")
                .font(.title2)
                .foregroundColor(AppColors.textPrimary)
        }
    }
    
    private var voiceButton: some View {
        Button(action: {
            // TODO: Implement voice commands
            HapticManager.impact(.medium)
        }) {
            Image(systemName: "mic.fill")
                .font(.title2)
                .foregroundColor(.white)
                .padding(AppSpacing.lg)
                .background(
                    LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, AppSpacing.md)
        .padding(.bottom, AppSpacing.md)
    }
}

#Preview {
    DashboardView()
}