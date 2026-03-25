//
//  6 - Tache.swift
//  CleanQuest_Back
//
//  Created by caroletm on 25/03/2026.
//

import Vapor
import Fluent

final class Tache: Model, Content, @unchecked Sendable {
    static let schema = "taches"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "nom") var nom : String
    @Field(key: "icone") var icone : String
    @Timestamp(key: "dateCreation", on: .create) var dateCreation : Date?
    @Enum(key: "frequence") var frequence: FrequenceTache
    @Field(key: "duree") var duree : Int
    @Enum(key: "difficulte") var difficulté : DifficulteTache
    @Field(key: "points") var points : Double
    @Field(key: "aFaireValider") var aFaireValider : Bool
    
    init() {
        self.id = UUID()
    }
    init( id: UUID? = nil, nom: String, icone: String, dateCreation: Date? = nil, frequence: FrequenceTache, duree: Int, difficulté: DifficulteTache, points: Double, aFaireValider: Bool) {
        self.id = UUID()
        self.nom = nom
        self.icone = icone
        self.dateCreation = dateCreation
        self.frequence = frequence
    }
    
}
