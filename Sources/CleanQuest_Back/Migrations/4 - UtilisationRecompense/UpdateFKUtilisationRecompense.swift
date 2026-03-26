//
//  UpdateUtilisationRecompense.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//

import Fluent

struct UpdateFKUtilisationRecompense: AsyncMigration {
    
    func prepare(on db: any Database) async throws {
        try await db.schema("utilisation_recompense")
            .field("proprietaire_id", .uuid,
                .references("membres", "id", onDelete : .cascade))
            .field("destinataire_id", .uuid,
                .references("membres", "id", onDelete : .cascade))
            .field("recompense_id", .uuid,
                   .references("recompenses", "id", onDelete : .cascade))
            .update()
    }
    
    func revert(on db: any Database) async throws {
        try await db.schema("utilisation_recompense")
            .deleteField("proprietaire_id")
            .deleteField("destinataire_id")
            .deleteField( "recompense_id")
            .update()
    }
}

