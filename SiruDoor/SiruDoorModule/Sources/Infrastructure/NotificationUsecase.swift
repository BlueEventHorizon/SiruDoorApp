//
//  NotificationView.swift
//  SiruDoorMonitor
//
//  Created by Katsuhiko Terada on 2022/08/05.
//

import Foundation
import UserNotifications

#if canImport(Cocoa)
    import Cocoa
#endif

// https://developer.apple.com/documentation/usernotifications/scheduling_a_notification_locally_from_your_app

// macOSアプリで通知バナーを表示
// https://qiita.com/IKEH/items/66291cf836dc4918d9a8

public class NotificationUsecase: NSObject {
    public static let `default` = NotificationUsecase()

    private var isRemoteNotificationEnabled: Bool?
    private let userNotificationCenter = UNUserNotificationCenter.current()

    override init() {
        super.init()

        userNotificationCenter.delegate = self
    }

    func testNotify() {
        Task.detached {
            let settings = await self.userNotificationCenter.notificationSettings()
            if settings.authorizationStatus == .authorized {
                self.present(content: SimpleNotificationContent(title: "ローカル", subtitle: "テスト", body: "🙆‍♂️🙆‍♂️🙆‍♂️🙆‍♂️", image: nil))
            }
        }
    }

    public func present(content: SimpleNotificationContent) {
        #if os(iOS)

            Task.detached {
                if let granted = await self.requestAuthorization(), granted {
                    self.sendLocalNotification(title: content.title, body: content.body)
                }
            }

        #else
            let notification = UNMutableNotificationContent()

            notification.title = content.title
            notification.subtitle = content.subtitle
            notification.body = content.body
            notification.sound = UNNotificationSound.default
            notification.interruptionLevel = .timeSensitive
            notification.relevanceScore = 1.0
            if let image = makeImageAttachment() {
                notification.attachments.append(image)
            }

            // let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil) // Schedule the notification.

            Task.detached {
                do {
                    try await self.userNotificationCenter.add(request)
                } catch {
                    print(error)
                }
            }
        #endif
    }

    // 画像表示用のAttachmentを作成します。
    public func makeImageAttachment() -> UNNotificationAttachment? {
        let options: [AnyHashable: Any] = [
            // UNNotificationAttachmentOptionsTypeHintKey : kUTTypeJPEG,
            // UNNotificationAttachmentOptionsThumbnailClippingRectKey : CGRect(x: 0, y: 0, width: 1, height: 1).dictionaryRepresentation,
            // UNNotificationAttachmentOptionsThumbnailTimeKey:2,
            UNNotificationAttachmentOptionsThumbnailHiddenKey: false
        ] as [String: Any]

        if let imageURL = Bundle.main.url(forResource: "deliveryman", withExtension: "png"),
           let imageAttachment = try? UNNotificationAttachment(identifier: UUID().uuidString, url: imageURL, options: options) {
            return imageAttachment
        }
        return nil
    }

    public func auth() {
        Task.detached {
            try await self.userNotificationCenter.requestAuthorization(options: [.alert, .sound])
        }
    }

    public func openNotificationSettingOfSystemPreference() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") else {
            return
        }

        #if os(iOS)

        #else
            NSWorkspace.shared.open(url)
        #endif
    }
}

extension NotificationUsecase: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .sound, .badge])
    }
}

extension NotificationUsecase {
    #if os(iOS)
        // 起動時に呼び出すことで、初回のみOSの許可ダイアログが現れます
        func requestAuthorization(options: UNAuthorizationOptions = [.badge, .sound, .alert]) async -> Bool? {
            if let result = isRemoteNotificationEnabled {
                // 既に決定済み
                return result
            }

            let center = UNUserNotificationCenter.current()
            center.delegate = self // UNUserNotificationCenterDelegate

            do {
                isRemoteNotificationEnabled = try await center.requestAuthorization(options: options)
            } catch {
                assertionFailure(error.localizedDescription)
            }

            return isRemoteNotificationEnabled
        }

        /// ローカルプッシュを発行する
        @discardableResult
        func sendLocalNotification(title: String, body: String, timeInterval: TimeInterval = 0.01) -> String {
            let uuidString = UUID().uuidString

            // UNMutableNotificationContent 作成
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = UNNotificationSound.default

            // (timeInterval)秒後に発火する UNTimeIntervalNotificationTrigger 作成、
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            // let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(), repeats: false)

            // identifier, content, trigger から UNNotificationRequest 作成
            let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)

            // UNUserNotificationCenter に request を追加
            let center = UNUserNotificationCenter.current()
            center.add(request)

            return uuidString
        }
    #else

    #endif
}
