//
//  8 - CategorieTache.swift
//  CleanQuest_Back
//
//  Created by caroletm on 25/03/2026.
//

import Vapor
import Fluent

final class CategorieTache : Model, Content, @unchecked Sendable {
    static let schema = "categorie_taches"
    
    @ID(key: .id) var id : UUID?
    @Field(key: "nom") var nom : String
    
    init() {
        self.id = UUID()
    }
    init(id: UUID? = nil, nom: String) {
        self.id = UUID()
        self.nom = nom
    }
}
