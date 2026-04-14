//
//  CreateUser.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//


import Fluent

struct CreateUser: AsyncMigration {
    
    func prepare(on db: any Database) async throws {
        try await db.schema("users")
            .id()
            .field("nom", .string, .required)
            .field("email", .string, .required).unique(on: "email")
            .field("motDePasse", .string, .required)
            .create()
    }

    func revert(on db: any Database) async throws {
        try await db.schema("users").delete()
    }
}
