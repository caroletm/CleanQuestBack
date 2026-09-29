//
//  PurgeService.swift
//  CleanQuest_Back
//
//  Created by caroletm on 29/09/2026.
//

import Vapor
import Fluent

// Supprime les occurrences qui ne servent plus à rien, pour limiter la taille de la base.
// Remplace l'EVENT MySQL (scripts/purge_occurrences.sql) qui dépendait d'un réglage serveur.
struct PurgeService {

    /// Au-delà, une tâche ratée n'apparaît plus dans « En retard » côté app.
    static let joursRetardAffiches = 7
    /// Le Suivi remonte au plus à « ce mois-ci » / « la semaine dernière ».
    static let joursHistorique = 45

    static func demarrer(app: Application) {
        app.eventLoopGroup.next().scheduleRepeatedAsyncTask(initialDelay: .minutes(1), delay: .hours(24)) { _ in
            let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
            promise.completeWithTask {
                await purger(app: app)
            }
            return promise.futureResult
        }
    }

    static func purger(app: Application) async {
        let maintenant = Date()
        let limiteRetard = maintenant.addingTimeInterval(-Double(joursRetardAffiches) * 86_400)
        let limiteHistorique = maintenant.addingTimeInterval(-Double(joursHistorique) * 86_400)

        do {
            // Tâches ratées des séries récurrentes : la suivante a déjà pris le relais.
            // Une tâche unique pas faite reste à faire : on ne la supprime jamais.
            let rateesIds = try await OccurenceTache.query(on: app.db)
                .join(Tache.self, on: \OccurenceTache.$tache.$id == \Tache.$id)
                .filter(\.$statut ~~ [.aFaire, .nonValidee])
                .filter(\.$datePlanifiee < limiteRetard)
                .filter(Tache.self, \.$frequence != .unique)
                .all(\.$id)
                .compactMap { $0 }

            if !rateesIds.isEmpty {
                try await OccurenceTache.query(on: app.db)
                    .filter(\.$id ~~ rateesIds)
                    .delete()
            }

            let ancienNombre = try await OccurenceTache.query(on: app.db)
                .filter(\.$statut ~~ [.validee, .enAttenteDeValidation, .enCours])
                .filter(\.$datePlanifiee < limiteHistorique)
                .count()

            try await OccurenceTache.query(on: app.db)
                .filter(\.$statut ~~ [.validee, .enAttenteDeValidation, .enCours])
                .filter(\.$datePlanifiee < limiteHistorique)
                .delete()

            app.logger.info("🧹 Purge : \(rateesIds.count) occurrence(s) ratée(s), \(ancienNombre) ancienne(s) supprimée(s)")
        } catch {
            app.logger.error("Purge des occurrences : \(error)")
        }
    }
}
