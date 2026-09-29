//
//  PushService.swift
//  CleanQuest_Back
//
//  Created by caroletm on 28/09/2026.
//

import Vapor
import Fluent
import APNSCore
import VaporAPNS

// notifId reprend les ids des notifs du front (ex. "mission-<id>") pour ouvrir le bon écran au tap.
struct PushPayload: Codable, Sendable {
    let notifId: String?
}

struct PushService {

    static func envoyer(a userId: UUID, titre: String, message: String, notifId: String? = nil, on req: Request) async {
        await envoyer(a: userId, titre: titre, message: message, notifId: notifId, app: req.application)
    }

    // Version sans Request : utilisée par le job d'expiration, qui tourne en dehors de toute route.
    static func envoyer(a userId: UUID, titre: String, message: String, notifId: String? = nil, app: Application) async {
        guard let topic = Environment.get("APNS_TOPIC"),
              let apns = app.apns.containers.container() else {
            app.logger.warning("APNs non configuré : push non envoyé")
            return
        }

        let tokens: [DeviceToken]
        let badge: Int
        do {
            tokens = try await DeviceToken.query(on: app.db)
                .filter(\.$user.$id == userId)
                .all()
            guard !tokens.isEmpty, let user = try await User.find(userId, on: app.db) else { return }
            // APNs ne sait pas faire « +1 » : on envoie le nombre exact à afficher sur l'icône.
            user.badge += 1
            try await user.save(on: app.db)
            badge = user.badge
        } catch {
            app.logger.error("Lecture des device tokens : \(error)")
            return
        }

        let notification = APNSAlertNotification(
            alert: .init(title: .raw(titre), body: .raw(message)),
            expiration: .immediately,
            priority: .immediately,
            topic: topic,
            payload: PushPayload(notifId: notifId),
            badge: badge,
            sound: .default
        )

        for deviceToken in tokens {
            do {
                _ = try await apns.client.sendAlertNotification(notification, deviceToken: deviceToken.token)
                app.logger.info("✅ Push accepté par Apple")
            } catch {
                app.logger.error("Envoi du push : \(error)")
            }
        }
    }
}
