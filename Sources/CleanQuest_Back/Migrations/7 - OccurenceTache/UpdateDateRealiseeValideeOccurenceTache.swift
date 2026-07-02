//
//  UpdateDateRealiseeValideeOccurenceTache.swift
//  CleanQuest_Back
//
//  Created by caroletm on 29/06/2026.
//

import Fluent
import FluentSQL

struct UpdateDatesRealiseeValideeOccurenceTache: AsyncMigration {

    func prepare(on db: any Database) async throws {
        guard let sql = db as? any SQLDatabase else {
            try await db.schema("occurence_tache")
                .updateField("dateRealisee", .datetime)
                .updateField("dateValidee", .datetime)
                .update()
            return
        }
        try await sql.raw("ALTER TABLE occurence_tache MODIFY COLUMN dateRealisee DATETIME(6) NULL").run()
        try await sql.raw("ALTER TABLE occurence_tache MODIFY COLUMN dateValidee DATETIME(6) NULL").run()
    }

    func revert(on db: any Database) async throws {
        guard let sql = db as? any SQLDatabase else {
            try await db.schema("occurence_tache")
                .updateField("dateRealisee", .date)
                .updateField("dateValidee", .date)
                .update()
            return
        }
        try await sql.raw("ALTER TABLE occurence_tache MODIFY COLUMN dateRealisee DATE NULL").run()
        try await sql.raw("ALTER TABLE occurence_tache MODIFY COLUMN dateValidee DATE NULL").run()
    }
}
