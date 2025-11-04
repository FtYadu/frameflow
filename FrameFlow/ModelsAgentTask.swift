//
//  AgentTask.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation

struct AgentTask: Codable, Identifiable {
    let id: String
    let agentId: String
    let userId: String
    let taskType: String
    let priority: String
    let status: String
    let inputData: TaskInputData?
    let outputData: TaskOutputData?
    let requiresApproval: Bool
    let approvedByUser: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case agentId = "agent_id"
        case userId = "user_id"
        case taskType = "task_type"
        case priority
        case status
        case inputData = "input_data"
        case outputData = "output_data"
        case requiresApproval = "requires_approval"
        case approvedByUser = "approved_by_user"
        case createdAt = "created_at"
    }
    
    var taskStatus: TaskStatus? {
        return TaskStatus(rawValue: status)
    }
    
    var priorityLevel: TaskPriority? {
        return TaskPriority(rawValue: priority)
    }
    
    var canApprove: Bool {
        return requiresApproval && !approvedByUser && status == "pending"
    }
}

enum TaskPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .low: return AppColors.success
        case .medium: return AppColors.warning
        case .high: return AppColors.primary
        case .urgent: return AppColors.danger
        }
    }
}

// MARK: - Task Data Structures
struct TaskInputData: Codable {
    let leadId: String?
    let postId: String?
    let message: String?
    let imageUrl: String?
    let targetAudience: String?
    let brandVoice: String?
    
    enum CodingKeys: String, CodingKey {
        case leadId = "lead_id"
        case postId = "post_id"
        case message
        case imageUrl = "image_url"
        case targetAudience = "target_audience"
        case brandVoice = "brand_voice"
    }
}

struct TaskOutputData: Codable {
    let leadInfo: LeadInfo?
    let outreachMessage: String?
    let caption: String?
    let hashtags: [String]?
    let scheduledTime: Date?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case leadInfo = "lead_info"
        case outreachMessage = "outreach_message"
        case caption
        case hashtags
        case scheduledTime = "scheduled_time"
        case error
    }
}

struct LeadInfo: Codable {
    let name: String
    let instagram: String?
    let email: String?
    let industry: String
    let score: Int
    let reasoning: String
}

// MARK: - Task Approval
struct TaskApprovalRequest: Codable {
    let approved: Bool
    let feedback: String?
}