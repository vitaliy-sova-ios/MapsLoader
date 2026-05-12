//
//  NotificationService.swift
//  TestMapLoader
//
//  Created by Vitaliy on 11.05.2026.
//

import UserNotifications

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

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
