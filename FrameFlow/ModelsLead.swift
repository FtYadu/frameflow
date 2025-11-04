//
//  Lead.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation

struct Lead: Codable, Identifiable {
    let id: String
    let userId: String
    let companyName: String?
    let contactEmail: String?
    let instagramHandle: String?
    let leadScore: Int
    let reasoning: String?
    let source: String
    let status: String
    let discoveredAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case companyName = "company_name"
        case contactEmail = "contact_email"
        case instagramHandle = "instagram_handle"
        case leadScore = "lead_score"
        case reasoning
        case source
        case status
        case discoveredAt = "discovered_at"
    }
    
    var leadStatus: LeadStatus? {
        return LeadStatus(rawValue: status)
    }
    
    var scoreColor: Color {
        switch leadScore {
        case 0...40: return AppColors.danger
        case 41...70: return AppColors.warning
        case 71...100: return AppColors.success
        default: return AppColors.textSecondary
        }
    }
    
    var displayName: String {
        return companyName ?? instagramHandle ?? contactEmail ?? "Unknown Lead"
    }
}

enum LeadStatus: String, CaseIterable {
    case new = "new"
    case contacted = "contacted"
    case responded = "responded"
    case interested = "interested"
    case notInterested = "not_interested"
    case converted = "converted"
    
    var displayName: String {
        switch self {
        case .new: return "New"
        case .contacted: return "Contacted"
        case .responded: return "Responded"
        case .interested: return "Interested"
        case .notInterested: return "Not Interested"
        case .converted: return "Converted"
        }
    }
    
    var color: Color {
        switch self {
        case .new: return AppColors.warning
        case .contacted: return AppColors.primary
        case .responded: return AppColors.secondary
        case .interested: return AppColors.success
        case .notInterested: return AppColors.danger
        case .converted: return AppColors.success
        }
    }
}

// MARK: - Lead Update
struct LeadStatusUpdate: Codable {
    let status: String
    let notes: String?
}

// MARK: - Outreach Request
struct OutreachRequest: Codable {
    let message: String
    let platform: String // "email" or "instagram"
}