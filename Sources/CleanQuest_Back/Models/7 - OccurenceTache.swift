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
    @OptionalField(key: "dateRealisee") var dateRealisee: Date?
    @OptionalField(key: "dateValidee") var dateValidee : Date?
    @Enum(key : "statut") var statut: StatutTache
    
    @OptionalParent(key: "realisateur_id") var realisateur: Membre?
    @OptionalParent(key: "validateur_id") var validateur: Membre?
    @Parent(key: "tache_id") var tache: Tache

    init() {
        self.id = UUID()
    }
    init(
        id: UUID? = nil,
        datePlanifiee: Date,
        dateRealisee: Date? = nil,
        dateValidee: Date? = nil,
        statut: StatutTache,
        tacheId: UUID,
        realisateurId: UUID? = nil,
        validateurId: UUID? = nil
    ) {
        self.id = id ?? UUID()
        self.datePlanifiee = datePlanifiee
        self.dateRealisee = dateRealisee
        self.dateValidee = dateValidee
        self.statut = statut
        self.$tache.id = tacheId
        self.$realisateur.id = realisateurId
        self.$validateur.id = validateurId
    }
}
