//
//  User.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String
    let instagramHandle: String?
    let niche: String?
    let location: Location?
    let subscriptionTier: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case instagramHandle = "instagram_handle"
        case niche
        case location
        case subscriptionTier = "subscription_tier"
        case createdAt = "created_at"
    }
}

struct Location: Codable {
    let city: String
    let state: String?
    let country: String
    let latitude: Double?
    let longitude: Double?
}

// MARK: - Auth Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignUpRequest: Codable {
    let email: String
    let password: String
    let fullName: String
    let instagramHandle: String?
    let niche: String?
    
    enum CodingKeys: String, CodingKey {
        case email, password
        case fullName = "full_name"
        case instagramHandle = "instagram_handle"
        case niche
    }
}

struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}