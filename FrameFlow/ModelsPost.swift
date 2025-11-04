//
//  Post.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation

struct Post: Codable, Identifiable {
    let id: String
    let userId: String
    let caption: String?
    let imageUrl: String?
    let hashtags: [String]
    let platform: String
    let scheduledFor: Date?
    let status: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case caption
        case imageUrl = "image_url"
        case hashtags
        case platform
        case scheduledFor = "scheduled_for"
        case status
        case createdAt = "created_at"
    }
    
    var postStatus: PostStatus? {
        return PostStatus(rawValue: status)
    }
    
    var isScheduled: Bool {
        return scheduledFor != nil && status == "scheduled"
    }
    
    var hashtagString: String {
        return hashtags.map { "#\($0)" }.joined(separator: " ")
    }
}

enum PostStatus: String, CaseIterable {
    case draft = "draft"
    case scheduled = "scheduled"
    case published = "published"
    case failed = "failed"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .draft: return AppColors.textSecondary
        case .scheduled: return AppColors.warning
        case .published: return AppColors.success
        case .failed: return AppColors.danger
        }
    }
}

// MARK: - Post Creation
struct CreatePostRequest: Codable {
    let caption: String?
    let imageUrl: String?
    let hashtags: [String]
    let platform: String
    let scheduledFor: Date?
    
    enum CodingKeys: String, CodingKey {
        case caption
        case imageUrl = "image_url"
        case hashtags
        case platform
        case scheduledFor = "scheduled_for"
    }
}

// MARK: - Post Update
struct UpdatePostRequest: Codable {
    let caption: String?
    let hashtags: [String]?
    let scheduledFor: Date?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case caption
        case hashtags
        case scheduledFor = "scheduled_for"
        case status
    }
}

// MARK: - Caption Generation
struct GenerateCaptionRequest: Codable {
    let imageUrl: String?
    let topic: String?
    let brandVoice: String?
    let targetAudience: String?
    
    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case topic
        case brandVoice = "brand_voice"
        case targetAudience = "target_audience"
    }
}

struct GenerateCaptionResponse: Codable {
    let caption: String
    let hashtags: [String]
}