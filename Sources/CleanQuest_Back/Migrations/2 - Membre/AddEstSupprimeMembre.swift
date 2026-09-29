//
//  AddEstSupprimeMembre.swift
//  CleanQuest_Back
//
//  Created by caroletm on 29/09/2026.
//

import Fluent
import FluentSQL

struct AddEstSupprimeMembre: AsyncMigration {

    func prepare(on db: any Database) async throws {
        try await db.schema("membres")
            .field("estSupprime", .bool, .required, .sql(.default(false)))
            .update()
    }

    func revert(on db: any Database) async throws {
        try await db.schema("membres")
            .deleteField("estSupprime")
            .update()
    }
}
