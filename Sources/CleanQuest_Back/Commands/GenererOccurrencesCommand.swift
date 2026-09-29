//
//  GenererOccurrencesCommand.swift
//  CleanQuest_Back
//
//  Maintenance manuelle de la fenêtre glissante d'occurrences (30 jours en
//  avant) pour toutes les tâches, tous foyers confondus :
//      swift run CleanQuest_Back generer-occurrences
//
//  En fonctionnement normal cette commande est inutile : la fenêtre est
//  prolongée à la lecture, foyer par foyer (voir TacheController.prolongerFenetre).
//  Elle reste pratique pour rattraper l'ensemble de la base d'un coup.
//  La suppression des vieilles occurrences est faite par PurgeService.
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
        let maintenant = Date()
        let fin = OccurrenceGenerator.finFenetre(depuis: maintenant)
        // Ne recrée jamais le passé : après une longue interruption, une tâche
        // quotidienne fabriquerait sinon un mois entier d'occurrences en retard.
        let plancher = OccurrenceGenerator.plancherAujourdhui(maintenant)

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
                apartir: plancher,
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
