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

struct TacheTemplateDTO: Content {
    var id: UUID?
    var nom: String
    var categorie_id: UUID
    var foyer_id: UUID?
}

struct TacheCreateDTO: Content {
    var id: UUID
    var nom: String
    var categorie_id: UUID
    var categorie_nom: String?
    var tache_template_id: UUID?
    var icone_id: UUID
    var frequence: FrequenceTache
    var duree: Int
    var difficulte: DifficulteTache
    var points: Double
    var aFaireValider: Bool
    var date_echeance: Date
}

struct TacheUpdateDTO: Content {
    var nom: String?
    var categorie_id: UUID?
    var icone_id: UUID?
    var frequence: FrequenceTache?
    var duree: Int?
    var difficulte: DifficulteTache?
    var points: Double?
    var aFaireValider: Bool?
}

struct TacheResponseDTO: Content {
    var id: UUID?
    var nom: String
    var categorie_id: UUID
    var foyer_id: UUID
    var icone_id: UUID
    var frequence: FrequenceTache
    var duree: Int
    var difficulte: DifficulteTache
    var points: Double
    var aFaireValider: Bool
    var dateCreation: Date?
}

struct OccurenceTacheUpdateDTO: Content {
    var datePlanifiee: Date?
    var statut: StatutTache?
    var realisateur_id: UUID?
    var validateur_id: UUID?
}

struct OccurenceTacheDTO: Content {
    var id: UUID?
    var datePlanifiee: Date
    var dateRealisee: Date?
    var dateValidee: Date?
    var statut: StatutTache
    var realisateur_id: UUID?
    var validateur_id: UUID?
    var tache_id: UUID
    var tache_nom: String
    var icone_nomFichier: String
    var categorie_id: UUID
    var categorie_nom: String
    var frequence : FrequenceTache
    var duree: Int
    var difficulte: DifficulteTache
    var points: Double
    var aFaireValider: Bool
}
