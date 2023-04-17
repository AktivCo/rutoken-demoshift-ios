//
//  NotificationManager.swift
//  demoshift
//
//  Created by Vova Badyaev on 07.12.2021.
//  Copyright © 2021 Aktiv Co. All rights reserved.
//

import UserNotifications


class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    override init() {
        super.init()
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.badge, .sound, .alert]) { granted, error in
                if granted == true && error == nil {
                    UNUserNotificationCenter.current().delegate = self
                }
            }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
                                -> Void) {
        completionHandler([.badge, .sound, .banner, .list])
    }

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
