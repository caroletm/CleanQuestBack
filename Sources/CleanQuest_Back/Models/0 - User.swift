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
    @OptionalField(key: "couleur") var couleur: String?
    @OptionalField(key: "avatar") var avatar: String?
    @Field(key: "cagnotte") var cagnotte : Double
    @Enum(key : "niveau") var niveau : Niveau
    
    @Children(for : \.$user) var membres: [Membre]
    @Children(for : \.$gestionnaire) var gestionnaires: [Membre]
    
    init() {
        self.id = UUID()
    }
    
    init(id: UUID? = nil, nom : String, email : String, motDePasse : String, couleur : String? = nil, avatar : String? = nil, cagnotte : Double = 0.0, niveau : Niveau = .debutant) {
        self.id = id ?? UUID()
        self.nom = nom
        self.email = email
        self.motDePasse = motDePasse
        self.couleur = couleur
        self.avatar = avatar
        self.cagnotte = cagnotte
        self.niveau = niveau
    }
}
