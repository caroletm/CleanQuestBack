//
//  CreateMembre.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//

import Fluent

struct CreateMembre : AsyncMigration {
    
    func prepare(on db: any Database) async throws {
        
        try await db.schema("membres")
        .id()
        .field("estGere", .bool)
        .field("dateEntree", .date)
        .create()
    }
    
    func revert(on db: any Database) async throws {
        try await db.schema("membres").delete()
    }
}
