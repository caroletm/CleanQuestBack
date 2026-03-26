//
//  UpdateFKTache.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//

import Fluent

struct UpdateFKTache: AsyncMigration {
    
    func prepare(on db: any Database) async throws {
        try await db.schema("taches")
            .field("categorie_id", .uuid,
                .references("categorie_tache", "id", onDelete : .cascade))
            .field("foyer_id", .uuid,
                   .references("foyers", "id", onDelete : .cascade))
            .update()
    }
    
    func revert(on db: any Database) async throws {
        try await db.schema("taches")
            .deleteField("categorie_id")
            .deleteField("foyer_id")
            .update()
    }
}
