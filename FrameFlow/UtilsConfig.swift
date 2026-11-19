//
//  Config.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation

enum Config {
    // MARK: - API Configuration
    // Local backend:    http://localhost:3000/api   (run `cd backend && npm start`)
    // Deployed backend: https://your-app.vercel.app/api
    // The active URL is the first non-empty value in FrameFlow.xcconfig / Info.plist
    // under the key API_BASE_URL; it falls back to localhost for development.

    static let apiBaseURL: String = {
        // Info.plist / xcconfig override wins (set API_BASE_URL per build config).
        if let override = Bundle.main.infoDictionary?["API_BASE_URL"] as? String,
           !override.isEmpty {
            return override
        }
        return "http://localhost:3000/api"
    }()

    static var isProduction: Bool {
        return apiBaseURL.contains("vercel") || apiBaseURL.contains("render") || apiBaseURL.contains("heroku")
    }

    static var isDevelopment: Bool {
        return apiBaseURL.contains("localhost") || apiBaseURL.contains("127.0.0.1")
    }
}
