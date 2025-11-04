//
//  NotificationsView.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.notifications.isEmpty {
                        Button("Clear All") {
                            Task {
                                await viewModel.markAllAsRead()
                            }
                        }
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.primary)
                    }
                }
            }
            .task {
                await viewModel.loadNotifications()
            }
        }
    }
    
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                if viewModel.notifications.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "No Notifications",
                        message: "You're all caught up! Notifications will appear here."
                    )
                } else {
                    ForEach(viewModel.notifications) { notification in
                        NotificationRowView(
                            notification: notification,
                            onTap: {
                                await viewModel.markAsRead(notification)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .refreshable {
            await viewModel.refreshNotifications()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                .scaleEffect(1.5)
            
            Text("Loading notifications...")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - Notifications ViewModel
@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var loadingState: LoadingState = .idle
    
    private let apiService = APIService.shared
    
    var isLoading: Bool {
        return loadingState.isLoading
    }
    
    func loadNotifications() async {
        loadingState = .loading
        
        do {
            notifications = try await apiService.fetchNotifications()
            loadingState = .success
        } catch {
            loadingState = .failure(error)
            print("Error loading notifications: \(error)")
        }
    }
    
    func refreshNotifications() async {
        await loadNotifications()
    }
    
    func markAsRead(_ notification: AppNotification) async {
        guard !notification.isRead else { return }
        
        do {
            let updatedNotification = try await apiService.markNotificationAsRead(id: notification.id)
            
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = updatedNotification
            }
        } catch {
            print("Error marking notification as read: \(error)")
        }
    }
    
    func markAllAsRead() async {
        let unreadNotifications = notifications.filter { !$0.isRead }
        
        for notification in unreadNotifications {
            await markAsRead(notification)
        }
    }
}

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
            .cardStyle()
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

#Preview {
    NotificationsView()
}