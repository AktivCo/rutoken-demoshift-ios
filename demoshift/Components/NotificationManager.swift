//
//  NotificationManager.swift
//  demoshift
//
//  Created by Vova Badyaev on 07.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import UserNotifications


class NotificationManager {
    func pushNotification(withTitle title: String, body: String = "") {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = UNNotificationSound.default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                DispatchQueue.main.async {
                    UNUserNotificationCenter.current().add(request)
                }
            default:
                break
            }
        }
    }
}
