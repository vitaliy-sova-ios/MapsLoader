//
//  NotificationService.swift
//  TestMapLoader
//
//  Created by Vitaliy on 11.05.2026.
//

import UserNotifications
import UIKit

final class NotificationService {

    static let shared = NotificationService()

    private init() {}

    func requestPermission() {

        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in

            if let error {
                print(error)
            }
        }
    }

    func showDownloadFinished() {

        let content = UNMutableNotificationContent()
        content.title = "Download completed"
        content.body = "All files downloaded successfully"
        content.sound = .default
        content.badge = 1

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
}
