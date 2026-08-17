//
//  UpdateUtilisationRecompense.swift
//  CleanQuest_Back
//
//  Created by caroletm on 17/08/2026.
//

import Fluent

struct UpdateUtilisationRecompense: AsyncMigration {
    
    func prepare(on db: any Database) async throws {
        try await db.schema("utilisation_recompense")
            .deleteField("dateAchat")
            .deleteField("dateUtilisation")
            .deleteField("deadline")
            .update()
        
        try await db.schema("utilisation_recompense")
            .field("dateAchat", .datetime)
            .field("dateUtilisation", .datetime)
            .field("deadline", .datetime)
            .update()
    }
    
    func revert(on db: any Database) async throws {
        try await db.schema("utilisation_recompense")
            .deleteField("dateAchat")
            .deleteField("dateUtilisation")
            .deleteField("deadline")
            .update()
        
        try await db.schema("utilisation_recompense")
            .field("dateAchat",.date)
            .field("dateUtilisation", .date)
            .field("deadline", .date, .required)
            .update()
    }
    
}
