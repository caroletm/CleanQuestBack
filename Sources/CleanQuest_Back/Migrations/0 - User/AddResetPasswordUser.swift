//
//  AddResetPasswordUser.swift
//  CleanQuest_Back
//
//  Created by caroletm on 29/09/2026.
//

import Fluent
import FluentSQL

struct AddResetPasswordUser: AsyncMigration {

    func prepare(on db: any Database) async throws {
        try await db.schema("users")
            .field("resetCode", .string)
            .field("resetExpiration", .datetime)
            .field("resetEssais", .int, .required, .sql(.default(0)))
            .update()
    }

    func revert(on db: any Database) async throws {
        try await db.schema("users")
            .deleteField("resetCode")
            .deleteField("resetExpiration")
            .deleteField("resetEssais")
            .update()
    }
}
