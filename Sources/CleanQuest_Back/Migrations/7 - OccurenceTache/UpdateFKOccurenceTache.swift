//
//  UpdateFKOccurenceTache.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//


import Fluent

struct UpdateFKOcurrenceTache: AsyncMigration {
    
    func prepare(on db: any Database) async throws {
        try await db.schema("occurence_tache")
            .field("realisateur_id", .uuid,
                .references("membres", "id", onDelete : .cascade))
            .field("validateur_id", .uuid,
                .references("membres", "id", onDelete : .cascade))
            .field("tache_id", .uuid,
                   .references("taches", "id", onDelete : .cascade))
            .update()
    }
    
    func revert(on db: any Database) async throws {
        try await db.schema("occurence_tache")
            .deleteField("realisateur_id")
            .deleteField("validateur_id")
            .deleteField( "tache_id")
            .update()
    }
}
