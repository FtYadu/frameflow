//
//  Notification.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation
import SwiftUI

struct AppNotification: Codable, Identifiable {
    let id: String
    let userId: String
    let type: String
    let title: String
    let message: String?
    let isRead: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case title
        case message
        case isRead = "is_read"
        case createdAt = "created_at"
    }
    
    var notificationType: NotificationType? {
        return NotificationType(rawValue: type)
    }
    
    var timeAgo: String {
        return createdAt.timeAgo()
    }
}

enum NotificationType: String, CaseIterable {
    case taskApproval = "task_approval"
    case leadFound = "lead_found"
    case postScheduled = "post_scheduled"
    case briefReady = "brief_ready"
    case agentError = "agent_error"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .taskApproval: return "Task Approval"
        case .leadFound: return "New Lead"
        case .postScheduled: return "Post Scheduled"
        case .briefReady: return "Brief Ready"
        case .agentError: return "Agent Error"
        case .system: return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .taskApproval: return "checkmark.circle"
        case .leadFound: return "person.crop.circle.badge.plus"
        case .postScheduled: return "calendar.badge.plus"
        case .briefReady: return "doc.text"
        case .agentError: return "exclamationmark.triangle"
        case .system: return "gear"
        }
    }
    
    var color: Color {
        switch self {
        case .taskApproval: return AppColors.warning
        case .leadFound: return AppColors.success
        case .postScheduled: return AppColors.primary
        case .briefReady: return AppColors.secondary
        case .agentError: return AppColors.danger
        case .system: return AppColors.textSecondary
        }
    }
}

// MARK: - Mark as Read Request
struct MarkNotificationReadRequest: Codable {
    let isRead: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case isRead = "is_read"
    }
}