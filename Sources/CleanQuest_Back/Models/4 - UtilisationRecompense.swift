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
    @Timestamp(key: "dateUtilisation", on: .update) var dateUtilisation : Date?
    @Enum(key : "statutRecompense") var statutRecompense : StatutRecompense
    @Field(key: "deadline") var deadline : Date
    
    @Parent(key: "proprietaire_id") var proprietaire: Membre
    @Parent(key: "destinataire_id") var destinataire: Membre
    @Parent(key: "recompense_id") var recompense: Recompense
    
    init() {
        self.id = UUID()
        
    }
    init(id: UUID? = nil, dateAchat: Date? = nil, dateUtilisation: Date? = nil, statutRecompense: StatutRecompense, deadline: Date) {
        self.id = UUID()
        self.dateAchat = dateAchat
        self.dateUtilisation = dateUtilisation
        self.statutRecompense = statutRecompense
        self.deadline = deadline
    }
}
