//
//  CreateTache.swift
//  CleanQuest_Back
//
//  Created by caroletm on 26/03/2026.
//

import Fluent

struct CreateTache : AsyncMigration {
    func prepare(on db: any Database) async throws {
        
        let FrequenceTache = try await db.enum("frequenceTache")
            .case("quotidienne")
            .case("biQuotidienne")
            .case("hebdomadaire")
            .case("biHebdomadaire")
            .case("mensuelle")
            .case("biMensuelle")
            .case("unique")
            .create()
        
        let DifficulteTache = try await db.enum("difficulteTache")
            .case("tresFacile")
            .case("facile")
            .case("moyenne")
            .case("difficile")
            .case("tresDifficile")
            .create()
        
        try await db.schema("taches")
            .id()
            .field("nom", .string, .required)
            .field("icone", .string, .required)
            .field("dateCreation", .date)
            .field("frequence", FrequenceTache, .required)
            .field("duree", .int, .required)
            .field("difficulte", DifficulteTache, .required)
            .field("points", .double, .required)
            .field("aFaireValider", .bool, .required)
            .create()
    }
    
    func revert(on db: any Database) async throws {
        try await db.schema("taches").delete()
        try await db.schema("frequenceTache").delete()
        try await db.schema("difficulteTache").delete()
    }
}
