//
//  CreateDeviceToken.swift
//  CleanQuest_Back
//
//  Created by caroletm on 28/09/2026.
//

import Fluent

struct CreateDeviceToken: AsyncMigration {
    func prepare(on db: any Database) async throws {
        try await db.schema("device_tokens")
            .id()
            .field("token", .string, .required)
            .field("user_id", .uuid, .required,
                   .references("users", "id", onDelete: .cascade))
            .unique(on: "token")
            .create()
    }

    func revert(on db: any Database) async throws {
        try await db.schema("device_tokens").delete()
    }
}
