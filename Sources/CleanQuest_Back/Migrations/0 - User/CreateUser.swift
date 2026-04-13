//
//  CreateUser.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//


import Fluent

struct CreateUser: AsyncMigration {
    
    func prepare(on db: any Database) async throws {
        
        let Niveau = try await db.enum("niveau")
            .case("debutant")
            .case("intermediaire")
            .case("confirme")
            .case("expert")
            .create()
        
        try await db.schema("users")
            .id()
            .field("nom", .string, .required)
            .field("email", .string, .required).unique(on: "email")
            .field("motDePasse", .string, .required)
            .field("couleur", .string)
            .field("avatar", .string)
            .field("cagnotte", .double, .required, .sql(.default(0.0)))
            .field("niveau", Niveau, .required, .sql(.default("debutant")))
            .create()
    }
    
    func revert(on db: any Database) async throws {
        try await db.schema("users").delete()
        try await db.enum("niveau").delete()
    }
}
