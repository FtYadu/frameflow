//
//  Config.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation

enum Config {
    static let apiBaseURL = "http://localhost:3000/api" // Development
    // static let apiBaseURL = "https://your-api.vercel.app/api" // Production
    
    static let keychainService = "com.frameflow.app"
    static let authTokenKey = "authToken"
    static let refreshTokenKey = "refreshToken"
    
    // Notification identifiers
    static let taskApprovalNotification = "task_approval"
    static let briefNotification = "daily_brief"
}