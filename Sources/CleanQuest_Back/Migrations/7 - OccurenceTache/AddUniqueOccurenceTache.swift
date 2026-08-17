//
//  AddUniqueOccurenceTache.swift
//  CleanQuest_Back
//
//  Une tâche ne peut avoir qu'une seule occurrence à une date/heure donnée.
//  Sans cette contrainte, deux membres du même foyer ouvrant l'app en même
//  temps déclenchent chacun une prolongation de la fenêtre glissante, lisent
//  la même « dernière occurrence » et insèrent le même lot de dates en double.
//
//  L'index unique est le garde-fou côté base ; le code qui insère tolère le
//  conflit et ignore les doublons (voir OccurrenceGenerator).
//

import Fluent
import FluentSQL

struct AddUniqueOccurenceTache: AsyncMigration {

    func prepare(on db: any Database) async throws {
        guard let sql = db as? any SQLDatabase else {
            try await db.schema("occurence_tache")
                .unique(on: "tache_id", "datePlanifiee", name: "uq_occurence_tache_date")
                .update()
            return
        }
        try await sql.raw("""
            ALTER TABLE occurence_tache
            ADD CONSTRAINT uq_occurence_tache_date UNIQUE (tache_id, datePlanifiee)
            """).run()
    }

    func revert(on db: any Database) async throws {
        guard let sql = db as? any SQLDatabase else {
            try await db.schema("occurence_tache")
                .deleteUnique(on: "tache_id", "datePlanifiee")
                .update()
            return
        }
        try await sql.raw("""
            ALTER TABLE occurence_tache
            DROP INDEX uq_occurence_tache_date
            """).run()
    }
}
