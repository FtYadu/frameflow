//
//  DashboardViewModel.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation
import Combine

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
    private var cancellables = Set<AnyCancellable>()
    
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
    
    init() {
        startAutoRefresh()
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
    
    // MARK: - Convenience Properties
    var isLoading: Bool {
        return loadingState.isLoading && !isRefreshing
    }
    
    var errorMessage: String? {
        if case .failure(let message) = loadingState {
            return message
        }
        return nil
    }
}
