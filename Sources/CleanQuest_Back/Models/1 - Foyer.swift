//
//  Foyer.swift
//  CleanQuest_Back
//
//  Created by caroletm on 25/03/2026.
//

import Vapor
import Fluent

final class Foyer : Model, Content, @unchecked Sendable {
    static let schema = "foyers"
    
    @ID(key: .id) var id : UUID?
    @Field(key: "nom") var nom: String
    @Enum(key: "type") var type: TypeFoyer
    @Field(key: "codeFoyer") var codeFoyer: String
    
    @Children(for: \.$foyer) var membres: [Membre]
    @Children(for : \.$foyer) var taches: [Tache]
    @Children(for: \.$foyer) var categoriesTache: [CategorieTache]
    
    init() {
        self.id = UUID()
    }
        init(id: UUID? = nil, nom : String, type: TypeFoyer, codeFoyer: String) {
        self.id = UUID()
        self.nom = nom
        self.type = type
        self.codeFoyer = codeFoyer
    }
}
