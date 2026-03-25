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
    @Field(key: "couleur") var couleur: String
    @Field(key: "avatar") var avatar: String
    @Field(key: "cagnotte") var cagnotte : Double
    @Enum(key : "niveau") var niveau : Niveau
    
    init() {
        self.id = UUID()
    }
    
    init(id: UUID? = nil, nom : String, email : String, motDePasse : String, couleur : String, avatar : String, cagnotte : Double, niveau : Niveau) {
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
