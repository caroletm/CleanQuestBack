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
    var dureeMinutes: Int
    var categorie_id: UUID
    var categorie_nom: String
}

struct UtilisationRecompenseCreateDTO : Content {
    var proprietaire_id: UUID
}

struct UtilisationRecompenseResponseDTO : Content {
    var id: UUID?
    var statutRecompense: StatutRecompense
    var dateAchat : Date?
    var dateUtilisation : Date?
    var deadline : Date?
    var proprietaire_id: UUID
    var destinataire_id: UUID?
    var recompense : RecompenseDTO
    var cagnotteProprietaire : Double
}

struct AttributionRecompenseDTO  : Content {
    var destinataire_id: UUID
}
    

struct TableauRecompensesDTO : Content {
    var achetees : [UtilisationRecompenseResponseDTO]
    var missions : [UtilisationRecompenseResponseDTO]
    var enCours : [UtilisationRecompenseResponseDTO]
    var nombreUtilisees : Int
}
