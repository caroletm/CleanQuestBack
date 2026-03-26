//
//  CreateFoyer.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//

import Fluent

struct CreateFoyer : AsyncMigration {
    
    func prepare(on db: any Database) async throws {
        
        let TypeFoyer = try await db.enum("typeFoyer")
            .case("solo")
            .case("familleAvecEnfant")
            .case("familleSansEnfant")
            .case("couple")
            .case("coloc")
            .create()
        
        try await db.schema("foyers")
            .id()
            .field("nom", .string, .required)
            .field("type", TypeFoyer, .required)
            .field("codeFoyer", .string, .required)
            .create()
    }
    
    func revert(on db: any Database) async throws {
        try await db.schema("foyers").delete()
        try await db.enum("typeFoyer").delete()
    }
    
}
