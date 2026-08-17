//
//  4 - UtilisationRecompense.swift
//  CleanQuest_Back
//
//  Created by caroletm on 25/03/2026.
//

import Vapor
import Fluent

final class UtilisationRecompense : Model, Content, @unchecked Sendable {
    static let schema = "utilisation_recompense"
    
    @ID(key: .id) var id: UUID?
    @Timestamp(key: "dateAchat", on: .create) var dateAchat : Date?
    @OptionalField(key: "dateUtilisation") var dateUtilisation : Date?
    @Enum(key : "statut") var statutRecompense : StatutRecompense
    @OptionalField(key: "deadline") var deadline : Date?
    @Parent(key: "proprietaire_id") var proprietaire: Membre
    @OptionalParent(key: "destinataire_id") var destinataire: Membre?
    @Parent(key: "recompense_id") var recompense: Recompense
    
    init() {
        self.id = UUID()
    }
    init(id: UUID? = nil, dateAchat: Date? = nil, dateUtilisation: Date? = nil, statutRecompense: StatutRecompense, deadline: Date? = nil, proprietaireId: Membre.IDValue, recompenseId: Recompense.IDValue) {
        self.id = id ?? UUID()
        self.dateAchat = dateAchat
        self.dateUtilisation = dateUtilisation
        self.statutRecompense = statutRecompense
        self.deadline = deadline
        self.$proprietaire.id = proprietaireId
        self.$recompense.id = recompenseId
    }
}
