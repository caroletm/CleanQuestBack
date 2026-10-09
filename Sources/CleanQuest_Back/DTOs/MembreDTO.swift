//
//  MembreDTO.swift
//  CleanQuest_Back
//
//  Created by caroletm on 16/04/2026.
//

import Vapor

struct MembreDTO : Content {
    var id: UUID?
    var estGere : Bool
    var dateEntree : Date?
    var nom : String
    var email : String?
    var couleur : String?
    var avatar : String?
    var cagnotte : Double
    var niveau : Niveau
    var userId : UUID?
    var gestionnaireId : UUID?
    var foyerId : UUID
    var estSupprime : Bool = false
}

struct CreateMembreDTO : Content {
    var estGere : Bool
    var nom : String
    var email : String?
    var couleur : String?
    var avatar : String?
    var userId : UUID?
    var gestionnaireId : UUID?
    var foyerId : UUID?
}

struct UpdateMembreDTO : Content {
    var nom : String?
    var couleur : String?
    var avatar : String?
}

struct MembreJoinDTO : Content {
    var email: String
    var codeFoyer: String
    // Apportés par celui qui rejoint : l'inviteur n'a saisi qu'un nom et un email.
    var nom: String?
    var couleur: String?
    var avatar: String?
}

struct MembreJoinResponse: Content {
    let membreId: UUID
    let foyerId: UUID
}
