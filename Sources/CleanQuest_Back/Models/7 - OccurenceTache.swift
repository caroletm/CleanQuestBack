//
//  7 - .swift
//  CleanQuest_Back
//
//  Created by caroletm on 25/03/2026.
//

import Fluent
import Vapor

final class OccurenceTache : Model, Content, @unchecked Sendable {
    static let schema = "occurence_tache"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "datePlanifiee") var datePlanifiee: Date
    @Timestamp(key: "dateRealisee", on: .update) var dateRealisee: Date?
    @Timestamp(key: "dateValidee", on: .update) var dateValidee : Date?
    @Field(key : "statut") var statut: StatutTache
    
    init() {
        self.id = UUID()
    }
    init( id: UUID? = nil, datePlanifiee: Date, dateRealisee: Date? = nil, dateValidee: Date? = nil, statut: StatutTache) {
        self.id = UUID()
        self.datePlanifiee = datePlanifiee
        self.dateRealisee = dateRealisee
        self.dateValidee = dateValidee
        self.statut = statut
    }
}
