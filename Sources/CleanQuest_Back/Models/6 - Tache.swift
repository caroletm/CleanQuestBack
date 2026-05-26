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
    @Parent(key: "icone_id") var icone: Icone
    @Timestamp(key: "dateCreation", on: .create) var dateCreation : Date?
    @Enum(key: "frequence") var frequence: FrequenceTache
    @Field(key: "duree") var duree : Int
    @Enum(key: "difficulte") var difficulte : DifficulteTache
    @Field(key: "points") var points : Double
    @Field(key: "aFaireValider") var aFaireValider : Bool
    
    @Children(for: \.$tache) var occurencesTache: [OccurenceTache]
    
    @Parent(key : "categorie_id") var categorie: CategorieTache
    @Parent(key : "foyer_id") var foyer: Foyer
    
    init() {
        self.id = UUID()
    }
    init(id: UUID? = nil, nom: String, icone_id: UUID, dateCreation: Date? = nil, frequence: FrequenceTache, duree: Int, difficulte: DifficulteTache, points: Double, aFaireValider: Bool) {
        self.id = id ?? UUID()
        self.nom = nom
        self.$icone.id = icone_id
        self.dateCreation = dateCreation
        self.frequence = frequence
        self.duree = duree
        self.difficulte = difficulte
        self.points = points
        self.aFaireValider = aFaireValider
    }
    
}
