//
//  TaskRowView.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import SwiftUI

struct TaskRowView: View {
    let task: AgentTask
    let onApprove: (Bool) async -> Void
    
    @State private var isProcessing = false
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Task type icon
            taskTypeIcon
            
            // Task content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(taskTitle)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                
                HStack {
                    // Priority badge
                    if let priority = task.priorityLevel {
                        PriorityBadge(priority: priority)
                    }
                    
                    // Status
                    Text(task.taskStatus?.displayName ?? task.status.capitalized)
                        .font(AppFonts.caption)
                        .foregroundColor(task.taskStatus?.color ?? AppColors.textSecondary)
                    
                    Spacer()
                    
                    // Time
                    Text(task.createdAt.timeAgo())
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // Action buttons
            if task.canApprove && !isProcessing {
                approvalButtons
            } else if isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                    .scaleEffect(0.8)
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
    
    private var taskTypeIcon: some View {
        ZStack {
            Circle()
                .fill(taskTypeColor.opacity(0.2))
                .frame(width: 40, height: 40)
            
            Image(systemName: taskTypeIconName)
                .foregroundColor(taskTypeColor)
                .font(.title3)
        }
    }
    
    private var approvalButtons: some View {
        HStack(spacing: AppSpacing.sm) {
            Button(action: {
                Task {
                    isProcessing = true
                    await onApprove(false)
                    isProcessing = false
                }
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(AppColors.danger)
                    .font(.title3)
                    .padding(8)
                    .background(AppColors.danger.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Button(action: {
                Task {
                    isProcessing = true
                    await onApprove(true)
                    isProcessing = false
                }
            }) {
                Image(systemName: "checkmark")
                    .foregroundColor(AppColors.success)
                    .font(.title3)
                    .padding(8)
                    .background(AppColors.success.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Computed Properties
    private var taskTitle: String {
        switch task.taskType {
        case "find_leads":
            return "Found new photography leads"
        case "send_outreach":
            if let leadInfo = task.outputData?.leadInfo {
                return "Send outreach to \(leadInfo.name)"
            }
            return "Send outreach message"
        case "generate_caption":
            return "Generated Instagram caption"
        case "schedule_post":
            return "Schedule Instagram post"
        default:
            return task.taskType.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    private var taskTypeIconName: String {
        switch task.taskType {
        case "find_leads":
            return "person.crop.circle.badge.plus"
        case "send_outreach":
            return "envelope"
        case "generate_caption":
            return "text.bubble"
        case "schedule_post":
            return "calendar.badge.plus"
        default:
            return "gear"
        }
    }
    
    private var taskTypeColor: Color {
        switch task.taskType {
        case "find_leads":
            return AppColors.primary
        case "send_outreach":
            return AppColors.secondary
        case "generate_caption", "schedule_post":
            return AppColors.success
        default:
            return AppColors.textSecondary
        }
    }
}

// MARK: - Priority Badge
struct PriorityBadge: View {
    let priority: TaskPriority
    
    var body: some View {
        Text(priority.displayName)
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priority.color)
            .cornerRadius(4)
    }
}

// MARK: - Task Approval View
struct TaskApprovalView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else {
                    tasksList
                }
            }
            .navigationTitle("Task Approvals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadDashboardData()
            }
        }
    }
    
    private var tasksList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                let pendingTasks = viewModel.tasks.filter { $0.canApprove }
                
                if pendingTasks.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle",
                        title: "All Caught Up!",
                        message: "No tasks need your approval right now"
                    )
                } else {
                    ForEach(pendingTasks) { task in
                        TaskDetailCard(
                            task: task,
                            onApprove: { approved in
                                await viewModel.approveTask(task, approved: approved)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                .scaleEffect(1.5)
            
            Text("Loading tasks...")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - Task Detail Card
struct TaskDetailCard: View {
    let task: AgentTask
    let onApprove: (Bool) async -> Void
    
    @State private var isProcessing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(taskTitle)
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(task.createdAt.timeAgo())
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                if let priority = task.priorityLevel {
                    PriorityBadge(priority: priority)
                }
            }
            
            // Task details
            if let outputData = task.outputData {
                taskDetails(outputData)
            }
            
            // Action buttons
            if !isProcessing {
                HStack(spacing: AppSpacing.md) {
                    Button("Reject") {
                        Task {
                            isProcessing = true
                            await onApprove(false)
                            isProcessing = false
                        }
                    }
                    .secondaryButton()
                    
                    Button("Approve") {
                        Task {
                            isProcessing = true
                            await onApprove(true)
                            isProcessing = false
                        }
                    }
                    .primaryButton()
                }
            } else {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                    
                    Text("Processing...")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
    
    @ViewBuilder
    private func taskDetails(_ outputData: TaskOutputData) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            switch task.taskType {
            case "send_outreach":
                if let leadInfo = outputData.leadInfo,
                   let message = outputData.outreachMessage {
                    outreachDetails(leadInfo: leadInfo, message: message)
                }
                
            case "generate_caption":
                if let caption = outputData.caption,
                   let hashtags = outputData.hashtags {
                    captionDetails(caption: caption, hashtags: hashtags)
                }
                
            default:
                Text("Task details not available")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    private func outreachDetails(leadInfo: LeadInfo, message: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Lead: \(leadInfo.name)")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPrimary)
            
            if let instagram = leadInfo.instagram {
                Text("Instagram: \(instagram)")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Text("Score: \(leadInfo.score)/100")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.success)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Message:")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(message)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(CornerRadius.small)
            }
        }
    }
    
    private func captionDetails(caption: String, hashtags: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Caption:")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(caption)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(CornerRadius.small)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Hashtags:")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(hashtags.map { "#\($0)" }.joined(separator: " "))
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.primary)
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(CornerRadius.small)
            }
        }
    }
    
    private var taskTitle: String {
        switch task.taskType {
        case "find_leads":
            return "New Leads Found"
        case "send_outreach":
            return "Send Outreach Message"
        case "generate_caption":
            return "Generated Caption"
        case "schedule_post":
            return "Schedule Post"
        default:
            return task.taskType.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        TaskRowView(
            task: AgentTask(
                id: "1",
                agentId: "agent1",
                userId: "user1",
                taskType: "send_outreach",
                priority: "high",
                status: "pending",
                inputData: nil,
                outputData: TaskOutputData(
                    leadInfo: LeadInfo(
                        name: "The Plaza Hotel",
                        instagram: "@theplaza",
                        email: "events@theplaza.com",
                        industry: "hospitality",
                        score: 85,
                        reasoning: "High-end venue, frequently posts events, good engagement rate"
                    ),
                    outreachMessage: "Hi! I'm a wedding photographer specializing in luxury venues. I'd love to discuss partnership opportunities.",
                    caption: nil,
                    hashtags: nil,
                    scheduledTime: nil,
                    error: nil
                ),
                requiresApproval: true,
                approvedByUser: false,
                createdAt: Date()
            ),
            onApprove: { _ in }
        )
        
        TaskRowView(
            task: AgentTask(
                id: "2",
                agentId: "agent2",
                userId: "user1",
                taskType: "generate_caption",
                priority: "medium",
                status: "completed",
                inputData: nil,
                outputData: nil,
                requiresApproval: false,
                approvedByUser: true,
                createdAt: Date()
            ),
            onApprove: { _ in }
        )
    }
    .padding()
    .background(AppColors.background)
}