//
//  User.swift
//  CleanQuest_Back
//
//  Created by caroletm on 24/03/2026.
//

import Vapor
import Fluent

final class User : Model, Content, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id) var id : UUID?
    @Field(key: "nom") var nom: String
    @Field(key: "email") var email: String
    @Field(key: "motDePasse") var motDePasse: String

    @Children(for : \.$user) var membres: [Membre]
    @Children(for : \.$gestionnaire) var gestionnaires: [Membre]

    init() {
        self.id = UUID()
    }

    init(id: UUID? = nil, nom : String, email : String, motDePasse : String) {
        self.id = id ?? UUID()
        self.nom = nom
        self.email = email
        self.motDePasse = motDePasse
    }
}
