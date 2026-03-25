//
//  5 - Recompense.swift
//  CleanQuest_Back
//
//  Created by caroletm on 25/03/2026.
//

import Vapor
import Fluent

final class Recompense : Model, Content, @unchecked Sendable {
    static let schema = "recompenses"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "nom") var nom: String
    @Field(key: "image") var image : String
    @Field(key: "points") var points: Double
    @Field(key: "descriptionLongue") var descriptionLongue: String
    @Field(key: "descriptionCourte") var descriptionCourte: String
    @Field(key: "descriptionEnCours") var descriptionEnCours: String
    @Field(key: "imageEnCours") var imageEnCours: String
    
    init() {
        self.id = UUID()
    }
    init(id: UUID? = nil, nom: String, image: String, points: Double, descriptionLongue: String, descriptionCourte: String, descriptionEnCours: String, imageEnCours: String) {
        self.id = UUID()
        self.nom = nom
        self.image = image
        self.points = points
        self.descriptionLongue = descriptionLongue
        self.descriptionCourte = descriptionCourte
    }
}
