//
//  UpdateFKRecompense.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//

import Fluent

struct UpdateFKRecompense: AsyncMigration {
    
    func prepare(on db: any Database) async throws {
        try await db.schema("recompenses")
            .field("categorie_id", .uuid,
                .references("categorie_recompense", "id", onDelete : .cascade))
            .update()
    }
    
    func revert(on db: any Database) async throws {
        try await db.schema("recompenses")
            .deleteField("categorie_id")
            .update()
    }
}
