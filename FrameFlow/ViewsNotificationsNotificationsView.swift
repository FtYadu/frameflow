//
//  NotificationsView.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import SwiftUI
import Combine

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
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
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if notification.isRead {
                                Button("Unread") {
                                    Task { await viewModel.markAsUnread(notification) }
                                }
                                .tint(.orange)
                            } else {
                                Button("Read") {
                                    Task { await viewModel.markAsRead(notification) }
                                }
                                .tint(.green)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await viewModel.delete(notification) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
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

#Preview {
    NotificationsView()
}
