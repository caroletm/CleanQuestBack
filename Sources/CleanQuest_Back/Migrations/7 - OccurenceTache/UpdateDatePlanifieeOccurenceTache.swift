//
//  UpdateDatePlanifieeOccurenceTache.swift
//  CleanQuest_Back
//
//  Passe datePlanifiee de DATE à DATETIME pour pouvoir stocker une heure,
//  nécessaire à la fréquence biQuotidienne (2 occurrences/jour à 12h d'écart).
//

import Fluent
import FluentSQL

struct UpdateDatePlanifieeOccurenceTache: AsyncMigration {

    func prepare(on db: any Database) async throws {
        guard let sql = db as? any SQLDatabase else {
            try await db.schema("occurence_tache").updateField("datePlanifiee", .datetime).update()
            return
        }
        try await sql.raw("ALTER TABLE occurence_tache MODIFY COLUMN datePlanifiee DATETIME(6) NOT NULL").run()
    }

    func revert(on db: any Database) async throws {
        guard let sql = db as? any SQLDatabase else {
            try await db.schema("occurence_tache").updateField("datePlanifiee", .date).update()
            return
        }
        try await sql.raw("ALTER TABLE occurence_tache MODIFY COLUMN datePlanifiee DATE NOT NULL").run()
    }
}
