//
//  UpdateFKMembre.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//

import Fluent

struct UpdateFKMembre: AsyncMigration {
    func prepare(on db: any Database) async throws {
        try await db.schema("membres")
            .field("user_id", .uuid,
                .references("users", "id", onDelete : .setNull))
            .field("gestionnaire_id", .uuid,
                .references("users", "id", onDelete : .cascade))
            .field("foyer_id", .uuid,
                   .references("foyers", "id", onDelete : .cascade))
        
            .update()
    }
    func revert(on db: any Database) async throws {
        try await db.schema("membres")
            .deleteField("user_id")
            .deleteField( "gestionnaire_id")
            .deleteField("foyer_id")
            .update()
    }
}
