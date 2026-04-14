//
//  2 - Membre.swift
//  CleanQuest_Back
//
//  Created by caroletm on 25/03/2026.
//

import Vapor
import Fluent

final class Membre : Model, Content, @unchecked Sendable {
    static let schema = "membres"
    
    @ID(key: .id) var id : UUID?
    @Field(key: "estGere") var estGere: Bool
    @Timestamp(key: "dateEntree", on: .create) var dateEntree: Date?
    @Field(key: "nom") var nom: String
    @OptionalField(key: "couleur") var couleur: String?
    @OptionalField(key: "avatar") var avatar: String?
    @Field(key: "cagnotte") var cagnotte: Double
    @Enum(key: "niveau") var niveau: Niveau

    @OptionalParent(key: "user_id") var user: User?
    @Parent(key: "gestionnaire_id") var gestionnaire: User
    @Parent(key: "foyer_id") var foyer: Foyer

    @Children(for: \.$proprietaire) var utilisationsRecompenseProprietaire: [UtilisationRecompense]
    @Children(for: \.$destinataire) var utilisationsRecompenseDestinataire: [UtilisationRecompense]

    @Children(for: \.$realisateur) var occurenceTacheRealisateur: [OccurenceTache]
    @Children(for: \.$validateur) var occurenceTacheValidateur: [OccurenceTache]
 
    init() {
        self.id = UUID()
    }

    init(id: UUID? = nil, estGere: Bool, dateEntree: Date, nom : String,  couleur: String? = nil, avatar: String? = nil, cagnotte: Double = 0.0, niveau: Niveau = .debutant) {
        self.id = id ?? UUID()
        self.estGere = estGere
        self.dateEntree = dateEntree
        self.nom = nom
        self.couleur = couleur
        self.avatar = avatar
        self.cagnotte = cagnotte
        self.niveau = niveau
    }
}
