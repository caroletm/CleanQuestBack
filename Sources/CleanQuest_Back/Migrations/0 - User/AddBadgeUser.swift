//
//  AddBadgeUser.swift
//  CleanQuest_Back
//
//  Created by caroletm on 29/09/2026.
//

import Fluent
import FluentSQL

struct AddBadgeUser: AsyncMigration {

    func prepare(on db: any Database) async throws {
        try await db.schema("users")
            .field("badge", .int, .required, .sql(.default(0)))
            .update()
    }

    func revert(on db: any Database) async throws {
        try await db.schema("users")
            .deleteField("badge")
            .update()
    }
}
