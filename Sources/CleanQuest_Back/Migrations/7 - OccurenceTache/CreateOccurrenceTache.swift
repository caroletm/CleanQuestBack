//
//  CreateOccurrenceTache.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//

import Fluent

struct CreateOccurenceTache: AsyncMigration {
    
    func prepare(on db: any Database) async throws {
        
        let StatutTache = try await db.enum("statutTache")
            .case("aFaire")
            .case("enCours")
            .case("enAttenteDeValidation")
            .case("validee")
            .case("nonValidee")
            .create()
        
        try await db.schema("occurence_tache")
            .id()
            .field("datePlanifiee", .date, .required)
            .field("dateRealisee", .date)
            .field("dateValidee", .date)
            .field("statut", StatutTache,.required)
            .create()
    }
    
    func revert(on db: any Database) async throws {
        try await db.schema("occurence_tache").delete()
        try await db.schema("statutTache").delete()
    }
}

