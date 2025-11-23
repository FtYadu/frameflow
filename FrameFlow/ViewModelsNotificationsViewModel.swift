//
//  NotificationsViewModel.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var loadingState: LoadingState = .idle

    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var isLoading: Bool {
        return loadingState.isLoading
    }

    var unreadCount: Int {
        return notifications.filter { !$0.isRead }.count
    }

    // MARK: - Load Notifications
    func loadNotifications() async {
        loadingState = .loading

        do {
            let fetchedNotifications = try await apiService.fetchNotifications()
            notifications = fetchedNotifications.sorted { $0.createdAt > $1.createdAt }
            loadingState = .success
        } catch {
            loadingState = .failure(error.localizedDescription)
            print("Error loading notifications: \(error)")
        }
    }

    // MARK: - Refresh Notifications
    func refreshNotifications() async {
        do {
            let fetchedNotifications = try await apiService.fetchNotifications()
            notifications = fetchedNotifications.sorted { $0.createdAt > $1.createdAt }
            HapticManager.impact(.light)
        } catch {
            print("Error refreshing notifications: \(error)")
        }
    }

    // MARK: - Mark As Read
    func markAsRead(_ notification: AppNotification) async {
        do {
            let updatedNotification = try await apiService.markNotificationAsRead(id: notification.id)

            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = updatedNotification
            }

            HapticManager.impact(.light)
        } catch {
            print("Error marking notification as read: \(error)")
        }
    }

    // MARK: - Mark As Unread
    func markAsUnread(_ notification: AppNotification) async {
        // Note: This method would need a corresponding API endpoint
        // For now, we'll just update locally as a placeholder
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            // Create updated notification with isRead = false
            var updatedNotification = notification
            // Since AppNotification properties are let, we need to create a new instance
            // For now, just provide feedback that the feature needs backend support
            print("Mark as unread requires backend API implementation")
            HapticManager.impact(.light)
        }
    }

    // MARK: - Delete Notification
    func delete(_ notification: AppNotification) async {
        // Note: This method would need a corresponding API endpoint
        // For now, we'll remove it locally
        notifications.removeAll { $0.id == notification.id }
        HapticManager.impact(.medium)
    }

    // MARK: - Mark All As Read
    func markAllAsRead() async {
        // Mark all unread notifications as read
        let unreadNotifications = notifications.filter { !$0.isRead }

        for notification in unreadNotifications {
            await markAsRead(notification)
        }

        HapticManager.notification(.success)
    }

    // MARK: - Clear All Read Notifications
    func clearAllRead() async {
        notifications.removeAll { $0.isRead }
        HapticManager.impact(.medium)
    }
}
