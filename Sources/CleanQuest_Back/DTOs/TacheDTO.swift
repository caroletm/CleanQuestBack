//
//  TacheDTO.swift
//  CleanQuest_Back
//
//  Created by caroletm on 13/05/2026.
//

import Vapor

struct CategorieTacheDTO: Content {
    var id: UUID?
    var nom: String
    var foyer_id: UUID?
}

struct TacheCreateDTO: Content {
    var nom: String
    var icone_id: UUID
    var frequence: FrequenceTache
    var duree: Int
    var difficulte: DifficulteTache
    var points: Double
    var aFaireValider: Bool
    var categorie_id: UUID
}
