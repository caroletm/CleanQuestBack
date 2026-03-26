//
//  UpdateFKCategorieTache.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//

import Fluent

struct UpdateFKCategorieTache: AsyncMigration {
    
    func prepare(on db: any Database) async throws {
        try await db.schema("categorie_tache")
            .field("foyer_id", .uuid,
                .references("foyers", "id", onDelete : .cascade))
            .update()
    }
    
    func revert(on db: any Database) async throws {
        try await db.schema("categorie_tache")
            .deleteField("foyer_id")
            .update()
    }
}
