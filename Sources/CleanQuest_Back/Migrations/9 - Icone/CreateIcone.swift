//
//  CreateIcone.swift
//  CleanQuest_Back
//
//  Created by caroletm on 13/05/2026.
//

import Fluent

struct CreateIcone: AsyncMigration {
    func prepare(on db: any Database) async throws {
        try await db.schema("icones")
            .id()
            .field("nom", .string, .required)
            .field("nomFichier", .string, .required)
            .create()
    }

    func revert(on db: any Database) async throws {
        try await db.schema("icones").delete()
    }
}
