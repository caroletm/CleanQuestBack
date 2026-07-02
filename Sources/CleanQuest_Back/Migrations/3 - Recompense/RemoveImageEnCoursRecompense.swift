//
//  RemoveImageEnCoursRecompense.swift
//  CleanQuest_Back
//
//  Supprime la colonne "imageEnCours" devenue inutile sur recompenses.
//

import Fluent

struct RemoveImageEnCoursRecompense: AsyncMigration {

    func prepare(on db: any Database) async throws {
        try await db.schema("recompenses")
            .deleteField("imageEnCours")
            .update()
    }

    func revert(on db: any Database) async throws {
        try await db.schema("recompenses")
            .field("imageEnCours", .string, .required)
            .update()
    }
}
