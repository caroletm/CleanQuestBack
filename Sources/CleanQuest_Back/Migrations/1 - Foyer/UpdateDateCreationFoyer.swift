//
//  UpdateDateCreationFoyer.swift
//  CleanQuest_Back
//
//  Created by caroletm on 04/09/2026.
//

import Fluent

struct UpdateDateCreationFoyer: AsyncMigration{
    
    func prepare(on db: any Database) async throws {
        try await db.schema("foyers")
            .field("dateCreation", .datetime)
            .update()
    }
    
    func revert(on db: any Database) async throws {
        try await db.schema("foyers")
            .deleteField("dateCreation")
            .update()
    }
}
