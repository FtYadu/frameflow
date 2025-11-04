//
//  SharedComponents.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import SwiftUI
import Combine

// MARK: - Stats Card
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
        .glassmorphismCard()
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

// MARK: - Agent Card View (Updated)
struct AgentCardView: View {
    let agent: Agent
    let onToggle: () async -> Void
    let onTrigger: (String) async -> Void
    
    @State private var isToggling = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                // Icon with status
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: agent.type?.gradientColors ?? [AppColors.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: agent.type?.icon ?? "gear")
                        .foregroundColor(.white)
                        .font(.title3)
                }
                
                Spacer()
                
                // Status indicator
                StatusDot(isActive: agent.isActive, isWorking: agent.isWorking)
            }
            
            // Agent info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(agent.type?.displayName ?? agent.agentType.capitalized)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(agent.statusDisplayName)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Controls
            HStack {
                Toggle("", isOn: Binding(
                    get: { agent.isActive },
                    set: { _ in
                        Task {
                            isToggling = true
                            await onToggle()
                            isToggling = false
                        }
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: agent.type?.gradientColors.first ?? AppColors.primary))
                .disabled(isToggling)
                
                Spacer()
                
                if agent.isActive {
                    triggerButton
                }
            }
        }
        .padding(AppSpacing.md)
        .glassmorphismCard()
        .opacity(isToggling ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isToggling)
    }
    
    private var triggerButton: some View {
        Button(action: {
            Task {
                let action = getDefaultAction(for: agent.type)
                await onTrigger(action)
            }
        }) {
            Image(systemName: "play.circle.fill")
                .foregroundColor(agent.type?.gradientColors.first ?? AppColors.primary)
                .font(.title3)
        }
        .disabled(agent.isWorking)
    }
    
    private func getDefaultAction(for agentType: AgentType?) -> String {
        switch agentType {
        case .scout:
            return "find_leads"
        case .marketing:
            return "generate_posts"
        case .editor:
            return "start_editing"
        case .finance:
            return "generate_invoice"
        case .none:
            return "start"
        }
    }
}

// MARK: - Status Dot
struct StatusDot: View {
    let isActive: Bool
    let isWorking: Bool
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(AppColors.cardBackground, lineWidth: 2)
            )
            .scaleEffect(isWorking ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isWorking)
    }
    
    private var statusColor: Color {
        if !isActive {
            return AppColors.textSecondary
        } else if isWorking {
            return AppColors.warning
        } else {
            return AppColors.success
        }
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
        .glassmorphismCard()
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
            .glassmorphismCard()
        }
        .disabled(isLoading)
        .buttonStyle(PlainButtonStyle())
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
        .glassmorphismCard()
    }
}

// MARK: - Task Row View (Updated)
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
        .glassmorphismCard()
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

// MARK: - Notification Row View
struct NotificationRowView: View {
    let notification: AppNotification
    let onTap: () async -> Void
    
    var body: some View {
        Button(action: {
            Task {
                await onTap()
            }
        }) {
            HStack(spacing: AppSpacing.md) {
                // Notification icon
                notificationIcon
                
                // Content
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(notification.title)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    if let message = notification.message {
                        Text(message)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Text(notification.timeAgo)
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(AppSpacing.md)
            .glassmorphismCard()
            .opacity(notification.isRead ? 0.7 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var notificationIcon: some View {
        ZStack {
            Circle()
                .fill(notification.notificationType?.color.opacity(0.2) ?? AppColors.textSecondary.opacity(0.2))
                .frame(width: 40, height: 40)
            
            Image(systemName: notification.notificationType?.icon ?? "bell")
                .foregroundColor(notification.notificationType?.color ?? AppColors.textSecondary)
                .font(.title3)
        }
    }
}
