//
//  AddDureeMinutesRecompense.swift
//  CleanQuest_Back
//
//  Ajoute la durée de validité de l'effet (en minutes) sur recompenses.
//  DEFAULT 1440 (24h) pour ne pas casser les lignes existantes.
//

import Fluent
import SQLKit

struct AddDureeMinutesRecompense: AsyncMigration {

    func prepare(on db: any Database) async throws {
        try await db.schema("recompenses")
            .field("dureeMinutes", .int, .required, .sql(.default(1440)))
            .update()
    }

    func revert(on db: any Database) async throws {
        try await db.schema("recompenses")
            .deleteField("dureeMinutes")
            .update()
    }
}
