//
//  10 - Icone.swift
//  CleanQuest_Back
//
//  Created by caroletm on 13/05/2026.
//

import Vapor
import Fluent

final class Icone: Model, Content, @unchecked Sendable {
    static let schema = "icones"

    @ID(key: .id) var id: UUID?
    @Field(key: "nom") var nom: String
    @Field(key: "nomFichier") var nomFichier: String  // ex: "aspirateur.png" dans Public/icones/

    init() {
        self.id = UUID()
    }

    init(id: UUID? = nil, nom: String, nomFichier: String) {
        self.id = id ?? UUID()
        self.nom = nom
        self.nomFichier = nomFichier
    }
}
