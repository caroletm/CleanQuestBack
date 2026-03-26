//
//  CreateCategorieTache.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//

import Fluent

struct CreateCategorieTache: AsyncMigration {
    
    func prepare(on db: any Database) async throws {
        
        try await db.schema("categorie_tache")
            .id()
            .field("nom", .string, .required)
            .create()
    }
    
    func revert(on db: any Database) async throws {
        try await db.schema("categorie_tache").delete()
    }
    
}
