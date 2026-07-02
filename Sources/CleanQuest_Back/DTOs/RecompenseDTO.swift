//
//  RecompenseDTO.swift
//  CleanQuest_Back
//
//  Created by caroletm on 02/07/2026.
//

import Vapor

struct RecompenseDTO: Content {
    var id: UUID?
    var nom: String
    var image: String
    var points: Double
    var descriptionCourte: String
    var descriptionLongue: String
    var descriptionEnCours: String
    var categorie_id: UUID
    var categorie_nom: String
}
