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
        do {
            let updatedNotification = try await apiService.setNotificationRead(
                id: notification.id,
                isRead: false
            )

            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = updatedNotification
            }

            HapticManager.impact(.light)
        } catch {
            print("Error marking notification as unread: \(error)")
            HapticManager.notification(.error)
        }
    }

    // MARK: - Delete Notification
    func delete(_ notification: AppNotification) async {
        do {
            try await apiService.deleteNotification(id: notification.id)
            notifications.removeAll { $0.id == notification.id }
            HapticManager.impact(.medium)
        } catch {
            print("Error deleting notification: \(error)")
            HapticManager.notification(.error)
        }
    }

    // MARK: - Mark All As Read
    func markAllAsRead() async {
        let unreadNotifications = notifications.filter { !$0.isRead }
        guard !unreadNotifications.isEmpty else { return }

        await withTaskGroup(of: Void.self) { group in
            for notification in unreadNotifications {
                group.addTask {
                    _ = try? await self.apiService.markNotificationAsRead(id: notification.id)
                }
            }
        }
        await refreshNotifications()
        HapticManager.notification(.success)
    }

    // MARK: - Clear All Read Notifications
    func clearAllRead() async {
        let readNotifications = notifications.filter { $0.isRead }
        guard !readNotifications.isEmpty else { return }

        await withTaskGroup(of: Void.self) { group in
            for notification in readNotifications {
                group.addTask {
                    _ = try? await self.apiService.deleteNotification(id: notification.id)
                }
            }
        }
        await refreshNotifications()
        HapticManager.impact(.medium)
    }
}
