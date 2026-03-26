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
    init(id: UUID? = nil, estGere : Bool, dateEntree: Date) {
        self.id = UUID()
        self.estGere = estGere
        self.dateEntree = dateEntree
    }
}
