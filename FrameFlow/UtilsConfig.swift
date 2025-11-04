//
//  Config.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation

enum Config {
    // MARK: - API Configuration
    // 🚀 DEPLOYMENT: Update this URL after deploying to Vercel
    static let apiBaseURL = "http://localhost:3000/api" // Development
    // static let apiBaseURL = "https://your-app.vercel.app/api" // Production
    
    // MARK: - Keychain Configuration  
    static let keychainService = "com.frameflow.app"
    static let authTokenKey = "authToken"
    static let refreshTokenKey = "refreshToken"
    
    // MARK: - Notification Configuration
    static let taskApprovalNotification = "task_approval"
    static let briefNotification = "daily_brief"
    
    // MARK: - Feature Flags
    static let enableAISettings = true
    static let enableVoiceCommands = false // TODO: Implement voice commands
    static let enablePushNotifications = true
}

// MARK: - Environment Detection
extension Config {
    static var isProduction: Bool {
        return apiBaseURL.contains("vercel") || apiBaseURL.contains("render") || apiBaseURL.contains("heroku")
    }
    
    static var isDevelopment: Bool {
        return apiBaseURL.contains("localhost") || apiBaseURL.contains("127.0.0.1")
    }
}