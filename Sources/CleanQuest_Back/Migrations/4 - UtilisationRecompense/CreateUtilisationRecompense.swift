//
//  CreateUtilisationRecompense.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//

import Fluent

struct CreateUtilisationRecompense: AsyncMigration {
    
    func prepare(on db: any Database) async throws {
        
        let StatutRecompense = try await db.enum("statutRecompense")
            .case("achetee")
            .case("attribuee")
            .case("enCours")
            .case("nonValidee")
            .case("validee")
            .create()
        
        try await db.schema("utilisation_recompense")
        .id()
        .field("dateAchat", .date)
        .field("dateUtilisation", .date)
        .field("statut", StatutRecompense, .required)
        .field("deadline", .date, .required)
        .create()
    }
    
    func revert(on db: any Database) async throws {
        try await db.schema("utilisation_recompense").delete()
        try await db.schema("statutRecompense").delete()
    }
}
