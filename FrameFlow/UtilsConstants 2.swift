//
//  Constants.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import SwiftUI
import UIKit

struct AppColors {
    static let background = Color(hex: "0F172A")      // Dark blue-gray
    static let surface = Color(hex: "1E293B")         // Lighter gray
    static let primary = Color(hex: "3B82F6")         // Blue
    static let secondary = Color(hex: "A855F7")       // Purple
    static let success = Color(hex: "10B981")         // Green
    static let warning = Color(hex: "F59E0B")         // Yellow
    static let danger = Color(hex: "EF4444")          // Red
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "94A3B8")
    static let cardBackground = Color(hex: "1E293B")
    static let divider = Color(hex: "374151")
}

struct AppFonts {
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let title = Font.system(size: 24, weight: .bold, design: .default)
    static let headline = Font.system(size: 18, weight: .semibold, design: .default)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
}

struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

struct CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 24
}

// MARK: - Agent Types
enum AgentType: String, CaseIterable {
    case scout = "scout"
    case marketing = "marketing"
    case editor = "editor"
    case finance = "finance"
    
    var displayName: String {
        switch self {
        case .scout: return "Scout Agent"
        case .marketing: return "Marketing Agent"
        case .editor: return "Editor Agent"
        case .finance: return "Finance Agent"
        }
    }
    
    var icon: String {
        switch self {
        case .scout: return "person.crop.circle.badge.plus"
        case .marketing: return "chart.line.uptrend.xyaxis"
        case .editor: return "scissors"
        case .finance: return "dollarsign.circle"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .scout: return [Color(hex: "3B82F6"), Color(hex: "1E40AF")]
        case .marketing: return [Color(hex: "10B981"), Color(hex: "059669")]
        case .editor: return [Color(hex: "A855F7"), Color(hex: "7C3AED")]
        case .finance: return [Color(hex: "F59E0B"), Color(hex: "D97706")]
        }
    }
}

// MARK: - Task Status
enum TaskStatus: String, CaseIterable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case failed = "failed"
    case approved = "approved"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return AppColors.warning
        case .inProgress: return AppColors.primary
        case .completed: return AppColors.success
        case .failed: return AppColors.danger
        case .approved: return AppColors.success
        case .rejected: return AppColors.danger
        }
    }
}