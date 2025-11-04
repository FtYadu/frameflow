//
//  DashboardView.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import SwiftUI
import Combine

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var authService = AuthService.shared
    @State private var showingNotifications = false
    @State private var showingAISettings = false
    
    var body: some View {
        NavigationStack {
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
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: AppSpacing.sm) {
                        aiSettingsButton
                        notificationButton
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
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
            .sheet(isPresented: $showingAISettings) {
                AISettingsView()
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
    
    private var aiSettingsButton: some View {
        Button(action: {
            showingAISettings = true
        }) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(AppColors.textPrimary)
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

// MARK: - Dashboard ViewModel (Updated)
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var agents: [Agent] = []
    @Published var tasks: [AgentTask] = []
    @Published var leads: [Lead] = []
    @Published var posts: [Post] = []
    @Published var notifications: [AppNotification] = []
    @Published var morningBrief: AgentBrief?
    
    @Published var loadingState: LoadingState = .idle
    @Published var isRefreshing = false
    
    private let apiService = APIService.shared
    private var refreshTimer: Timer?
    
    deinit {
        stopAutoRefresh()
    }
    
    // MARK: - Computed Properties
    var pendingTasksCount: Int {
        return tasks.filter { $0.canApprove }.count
    }
    
    var unreadNotificationsCount: Int {
        return notifications.filter { !$0.isRead }.count
    }
    
    var leadsCount: Int {
        return leads.count
    }
    
    var postsThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        return posts.filter { $0.createdAt >= weekAgo }.count
    }
    
    var engagementRate: String {
        // Mock data for now - in real app this would come from Instagram API
        return "4.2%"
    }
    
    var monthlyRevenue: String {
        // Mock data for now - in real app this would come from finance agent
        return "$0"
    }
    
    var activeAgentsCount: Int {
        return agents.filter { $0.isActive }.count
    }
    
    var isLoading: Bool {
        return loadingState.isLoading && !isRefreshing
    }
    
    var errorMessage: String? {
        if case .failure(let error) = loadingState {
            return error
        }
        return nil
    }
    
    // MARK: - Data Loading
    func loadDashboardData() async {
        guard !isRefreshing else { return }
        
        if loadingState != .loading {
            loadingState = .loading
        }
        
        do {
            // Load all data concurrently
            async let agentsData = apiService.fetchAgents()
            async let tasksData = apiService.fetchTasks()
            async let leadsData = apiService.fetchLeads()
            async let postsData = apiService.fetchPosts()
            async let notificationsData = apiService.fetchNotifications()
            
            // Wait for all requests to complete
            agents = try await agentsData
            tasks = try await tasksData
            leads = try await leadsData
            posts = try await postsData
            notifications = try await notificationsData
            
            // Load morning brief if available
            await loadMorningBrief()
            
            loadingState = .success
            startAutoRefresh()
            
        } catch {
            loadingState = .failure(error.localizedDescription)
            print("Dashboard loading error: \(error)")
        }
    }
    
    func refreshData() async {
        isRefreshing = true
        await loadDashboardData()
        isRefreshing = false
        
        HapticManager.impact(.light)
    }
    
    private func loadMorningBrief() async {
        do {
            // Try to get the morning brief (this might return nil if none exists)
            morningBrief = try await apiService.fetchAgentBrief(type: "morning")
        } catch {
            // Morning brief is optional, so we don't treat this as a critical error
            print("Could not load morning brief: \(error)")
        }
    }
    
    // MARK: - Agent Actions
    func toggleAgent(_ agent: Agent) async {
        do {
            let updatedAgent = try await apiService.toggleAgent(
                type: agent.agentType,
                isActive: !agent.isActive
            )
            
            // Update the agent in our array
            if let index = agents.firstIndex(where: { $0.id == agent.id }) {
                agents[index] = updatedAgent
            }
            
            HapticManager.impact(.medium)
            
        } catch {
            print("Error toggling agent: \(error)")
            HapticManager.notification(.error)
        }
    }
    
    func triggerAgent(_ agentType: AgentType, action: String) async {
        do {
            try await apiService.triggerAgent(type: agentType.rawValue, action: action)
            
            // Refresh data to show updated status
            await refreshData()
            
            HapticManager.notification(.success)
            
        } catch {
            print("Error triggering agent: \(error)")
            HapticManager.notification(.error)
        }
    }
    
    // MARK: - Task Actions
    func approveTask(_ task: AgentTask, approved: Bool) async {
        do {
            let updatedTask = try await apiService.approveTask(
                id: task.id,
                approved: approved
            )
            
            // Update the task in our array
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = updatedTask
            }
            
            HapticManager.notification(approved ? .success : .warning)
            
        } catch {
            print("Error approving task: \(error)")
            HapticManager.notification(.error)
        }
    }
    
    // MARK: - Notification Actions
    func markNotificationAsRead(_ notification: AppNotification) async {
        do {
            let updatedNotification = try await apiService.markNotificationAsRead(id: notification.id)
            
            // Update the notification in our array
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = updatedNotification
            }
            
        } catch {
            print("Error marking notification as read: \(error)")
        }
    }
    
    // MARK: - Auto Refresh
    private func startAutoRefresh() {
        // Refresh every 30 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshData()
            }
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

#Preview {
    DashboardView()
}