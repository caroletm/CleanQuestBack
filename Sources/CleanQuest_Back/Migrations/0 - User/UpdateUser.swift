//
//  UpdateUser.swift
//  CleanQuest_Back
//
//  Created by caroletm on 05/05/2026.
//

import Fluent

struct UpdateUser: AsyncMigration {
    func prepare(on db: any Database) async throws {
        try await db.schema("users")
            .field("onboarding", .bool)
            .update()
    }
    func revert(on db: any Database) async throws {
        try await db.schema("users").delete()
    }
}
    
