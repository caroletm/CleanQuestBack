//
//  CreateMembre.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//

import Fluent

struct CreateMembre : AsyncMigration {
    
    func prepare(on db: any Database) async throws {
        let niveau = try await db.enum("niveau")
            .case("debutant")
            .case("intermediaire")
            .case("confirme")
            .case("expert")
            .create()

        try await db.schema("membres")
            .id()
            .field("estGere", .bool, .required)
            .field("dateEntree", .datetime)
            .field("nom", .string, .required)
            .field("email", .string)
            .field("couleur", .string)
            .field("avatar", .string)
            .field("cagnotte", .double, .required, .sql(.default(0.0)))
            .field("niveau", niveau, .required, .sql(.default("debutant")))
            .create()
    }

    func revert(on db: any Database) async throws {
        try await db.schema("membres").delete()
        try await db.enum("niveau").delete()
    }
}
