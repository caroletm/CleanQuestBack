//
//  FoyerDTO.swift
//  CleanQuest_Back
//
//  Created by caroletm on 16/04/2026.
//

import Vapor

struct FoyerDTO: Content {
    var id: UUID?
    var nom: String
    var type: TypeFoyer
    var codeFoyer: String
    var membres : [MembreDTO]
}

struct CreateFoyerDTO: Content {
    var nom: String
    var type: TypeFoyer
    var membres: [CreateMembreDTO]
}

struct UpdateFoyerDTO: Content {
    var nom: String?
    var type: TypeFoyer?
    var codeFoyer: String?
}
