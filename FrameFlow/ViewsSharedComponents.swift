//
//  SharedComponents.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import SwiftUI
import Combine

// MARK: - Notification Row View
struct NotificationRowView: View {
    let notification: AppNotification
    let onTap: () async -> Void
    
    var body: some View {
        Button(action: {
            Task {
                await onTap()
            }
        }) {
            HStack(spacing: AppSpacing.md) {
                // Notification icon
                notificationIcon
                
                // Content
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(notification.title)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    if let message = notification.message {
                        Text(message)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Text(notification.timeAgo)
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(AppSpacing.md)
            .glassmorphismCard()
            .opacity(notification.isRead ? 0.7 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var notificationIcon: some View {
        ZStack {
            Circle()
                .fill(notification.notificationType?.color.opacity(0.2) ?? AppColors.textSecondary.opacity(0.2))
                .frame(width: 40, height: 40)
            
            Image(systemName: notification.notificationType?.icon ?? "bell")
                .foregroundColor(notification.notificationType?.color ?? AppColors.textSecondary)
                .font(.title3)
        }
    }
}

