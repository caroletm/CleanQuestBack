//
//  GenererOccurrencesCommand.swift
//  CleanQuest_Back
//
//  Commande déclenchée une fois par jour par un cron système :
//      swift run CleanQuest_Back generer-occurrences
//  Maintient la fenêtre glissante d'occurrences (30 jours en avant) pour
//  toutes les tâches. La suppression des vieilles occurrences est gérée
//  séparément par un script SQL planifié.
//

import Vapor
import Fluent

struct GenererOccurrencesCommand: AsyncCommand {
    struct Signature: CommandSignature {}

    var help: String {
        "Génère les occurrences de tâches manquantes sur une fenêtre glissante de 30 jours."
    }

    func run(using context: CommandContext, signature: Signature) async throws {
        let db = context.application.db
        let calendar = OccurrenceGenerator.calendrier()
        let maintenant = Date()
        let fin = calendar.date(
            byAdding: .day,
            value: OccurrenceGenerator.fenetreJours,
            to: maintenant
        ) ?? maintenant

        let taches = try await Tache.query(on: db).all()
        var total = 0

        for tache in taches where tache.frequence != .unique {
            let tacheId = try tache.requireID()

            // Ancre = plus ancienne occurrence existante (meilleure approximation
            // de l'échéance d'origine, qui n'est pas stockée sur la tâche).
            guard let ancre = try await OccurenceTache.query(on: db)
                .filter(\.$tache.$id == tacheId)
                .sort(\.$datePlanifiee, .ascending)
                .first()?
                .datePlanifiee else {
                continue // pas d'occurrence de référence : rien à prolonger
            }

            let creees = try await OccurrenceGenerator.genererOccurrences(
                pour: tache,
                ancre: ancre,
                jusqua: fin,
                on: db
            )
            total += creees
            if creees > 0 {
                context.console.print("Tâche « \(tache.nom) » : \(creees) occurrence(s) créée(s).")
            }
        }

        context.console.print("✅ Génération terminée : \(total) occurrence(s) créée(s) au total.")
    }
}
