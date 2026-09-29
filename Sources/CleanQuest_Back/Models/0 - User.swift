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
    @Field(key: "onboarding") var onboarding: Bool
    @Field(key: "badge") var badge: Int
    // Code de réinitialisation du mot de passe, haché comme un mot de passe.
    @OptionalField(key: "resetCode") var resetCode: String?
    @OptionalField(key: "resetExpiration") var resetExpiration: Date?
    @Field(key: "resetEssais") var resetEssais: Int

    @Children(for : \.$user) var membres: [Membre]
    @Children(for : \.$gestionnaire) var gestionnaires: [Membre]

    init() {
        self.id = UUID()
        self.badge = 0
        self.resetEssais = 0
    }

    init(id: UUID? = nil, nom : String, email : String, motDePasse : String, onboarding: Bool) {
        self.id = id ?? UUID()
        self.nom = nom
        self.email = email
        self.motDePasse = motDePasse
        self.onboarding = onboarding
        self.badge = 0
        self.resetEssais = 0
    }
}
