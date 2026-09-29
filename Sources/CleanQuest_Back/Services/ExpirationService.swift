//
//  ExpirationService.swift
//  CleanQuest_Back
//
//  Created by caroletm on 29/09/2026.
//

import Vapor
import Fluent

struct ExpirationService {

    static func demarrer(app: Application) {
        app.eventLoopGroup.next().scheduleRepeatedAsyncTask(initialDelay: .seconds(10), delay: .seconds(10)) { _ in
            let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
            promise.completeWithTask {
                await verifier(app: app)
            }
            return promise.futureResult
        }
    }

    static func verifier(app: Application) async {
        let expirees: [UtilisationRecompense]
        do {
            expirees = try await UtilisationRecompense.query(on: app.db)
                .filter(\.$statutRecompense != .achetee)
                .filter(\.$expirationNotifiee == false)
                .filter(\.$deadline <= Date())
                // Garde-fou : on ne rattrape pas les vieilles cartes si le serveur a été éteint longtemps.
                .filter(\.$deadline >= Date().addingTimeInterval(-3600))
                .with(\.$proprietaire)
                .with(\.$destinataire)
                .with(\.$recompense) { $0.with(\.$categorie) }
                .all()
        } catch {
            app.logger.error("Recherche des récompenses expirées : \(error)")
            return
        }

        for utilisation in expirees {
            await prevenir(utilisation, app: app)

            utilisation.expirationNotifiee = true
            do {
                try await utilisation.save(on: app.db)
            } catch {
                app.logger.error("Marquage expiration notifiée : \(error)")
            }
        }
    }

    private static func prevenir(_ utilisation: UtilisationRecompense, app: Application) async {
        let recompense = utilisation.recompense
        let proprietaire = utilisation.proprietaire
        let notifId = "expiree-\(utilisation.id?.uuidString ?? "")"
        // Déjà clôturée : le propriétaire vient de répondre « En as-tu bien profité ? », inutile de le relancer.
        let proprietaireAPrevenir = utilisation.statutRecompense == .attribuee || utilisation.statutRecompense == .enCours

        guard recompense.categorie.nom == "action", let destinataire = utilisation.destinataire else {
            if proprietaireAPrevenir, let userId = proprietaire.$user.id {
                await PushService.envoyer(
                    a: userId,
                    titre: "Privilège \(recompense.nom) terminé",
                    message: "Ton privilège a pris fin",
                    notifId: notifId,
                    app: app)
            }
            return
        }

        if proprietaireAPrevenir, let userId = proprietaire.$user.id {
            await PushService.envoyer(
                a: userId,
                titre: "⏰ Temps écoulé pour \(recompense.nom)",
                message: "\(destinataire.nom) a-t-il bien réalisé ton action ? Viens confirmer",
                notifId: notifId,
                app: app)
        }

        if let userId = destinataire.$user.id {
            await PushService.envoyer(
                a: userId,
                titre: "⏰ Temps écoulé pour \(recompense.nom)",
                message: "\(proprietaire.nom) doit confirmer que tu as bien réalisé son action",
                notifId: notifId,
                app: app)
        }
    }
}
