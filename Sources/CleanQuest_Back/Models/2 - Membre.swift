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
    @Timestamp(key: "dateEntree") var dateEntree: Date
    
    init() {
        self.id = UUID()
    }
    init(id: UUID? = nil, estGere : Bool, dateEntree: Date) {
        self.id = UUID()
        self.estGere = estGere
        self.dateEntree = dateEntree
    }
}
