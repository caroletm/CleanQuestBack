//
//  CreateRecompense.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//

import Fluent

struct CreateRecompense: AsyncMigration {
    
    func prepare(on db: any Database) async throws {
        try await db.schema("recompenses")
            .id()
            .field("nom", .string, .required)
            .field("image", .string, .required)
            .field("points", .double, .required)
            .field("descriptionLongue", .string, .required)
            .field("descriptionCourte", .string, .required)
            .field("descriptionEnCours", .string, .required)
            .field("imageEnCours", .string, .required)
            .create()
    }
    func revert(on db: any Database) async throws {
        try await db.schema("recompenses").delete()
    }
}
