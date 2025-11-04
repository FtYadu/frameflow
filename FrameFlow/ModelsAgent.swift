//
//  Agent.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation

struct Agent: Codable, Identifiable {
    let id: String
    let userId: String
    let agentType: String
    let isActive: Bool
    let status: String
    let currentTask: String?
    let lastActivityAt: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case agentType = "agent_type"
        case isActive = "is_active"
        case status
        case currentTask = "current_task"
        case lastActivityAt = "last_activity_at"
        case createdAt = "created_at"
    }
    
    var type: AgentType? {
        return AgentType(rawValue: agentType)
    }
    
    var statusDisplayName: String {
        switch status {
        case "idle": return "Waiting for tasks"
        case "working": return "Working on leads"
        case "paused": return "Paused"
        default: return status.capitalized
        }
    }
    
    var isWorking: Bool {
        return status == "working"
    }
}

// MARK: - Agent Status Update
struct AgentStatusUpdate: Codable {
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
    }
}

// MARK: - Agent Trigger
struct AgentTriggerRequest: Codable {
    let action: String
    let parameters: [String: String]?
}

// MARK: - Agent Brief
struct AgentBrief: Codable, Identifiable {
    let id: String
    let userId: String
    let briefType: String
    let briefDate: String
    let summary: String
    let actionItems: [ActionItem]
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case briefType = "brief_type"
        case briefDate = "brief_date"
        case summary
        case actionItems = "action_items"
        case createdAt = "created_at"
    }
}

struct ActionItem: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let priority: String
    let completed: Bool
}