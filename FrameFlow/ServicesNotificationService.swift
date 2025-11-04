//
//  NotificationService.swift
//  FrameFlow
//
//  Created by LMTD on 04/11/2025.
//

import Foundation
import UserNotifications
import UIKit
import Combine
import Combine

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
    }
    
    // MARK: - Permission Request
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    // MARK: - Schedule Local Notification
    func scheduleNotification(
        id: String,
        title: String,
        body: String,
        timeInterval: TimeInterval? = nil,
        userInfo: [String: Any] = [:]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        
        let trigger: UNNotificationTrigger?
        
        if let timeInterval = timeInterval {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        } else {
            trigger = nil // Immediate notification
        }
        
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // MARK: - Schedule Daily Brief Notification
    func scheduleDailyBriefNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Your Daily Brief is Ready"
        content.body = "Check out what your AI agents accomplished today"
        content.sound = .default
        content.userInfo = ["type": "daily_brief"]
        
        // Schedule for 9 AM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "daily_brief",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling daily brief notification: \(error)")
            }
        }
    }
    
    // MARK: - Cancel Notification
    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    // MARK: - Clear Badge
    func clearBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    // MARK: - Set Badge Count
    func setBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle different notification types
        if let type = userInfo["type"] as? String {
            handleNotificationTap(type: type, userInfo: userInfo)
        }
        
        completionHandler()
    }
    
    private func handleNotificationTap(type: String, userInfo: [AnyHashable: Any]) {
        DispatchQueue.main.async {
            switch type {
            case "task_approval":
                // Navigate to task approval screen
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToTaskApproval"),
                    object: nil,
                    userInfo: userInfo
                )
                
            case "daily_brief":
                // Navigate to dashboard
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToDashboard"),
                    object: nil
                )
                
            case "lead_found":
                // Navigate to leads screen
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToLeads"),
                    object: nil,
                    userInfo: userInfo
                )
                
            default:
                break
            }
        }
    }
}