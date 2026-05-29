//
//  MembreController.swift
//  CleanQuest_Back
//
//  Created by caroletm on 05/05/2026.
//

import Vapor
import Fluent

struct MembreController: RouteCollection {
    func boot(routes : any RoutesBuilder) throws {
        let membres = routes.grouped("membres")
        let protected = membres.grouped(JWTMiddleware())
        
        protected.post("join", use: joinFoyer)
        protected.get("foyer", ":foyerId", use: getMembresByFoyer)
        protected.get("geres", ":foyerId", use: getMembresGeres)
    }
    
    // POST /membres/join
    func joinFoyer(_ req: Request) async throws -> MembreJoinResponse {
        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id
        
        let dto = try req.content.decode(MembreJoinDTO.self)   // juste code + email
        
        // Trouver le foyer via code
        guard let foyer = try await Foyer.query(on: req.db)
            .filter(\.$codeFoyer == dto.codeFoyer)
            .first()
        else {
            throw Abort(.notFound, reason: "Aucun foyer avec ce code.")
        }
        
        // Trouver le membre avec cet email
        guard let membre = try await Membre.query(on: req.db)
            .filter(\.$foyer.$id == foyer.id!)
            .filter(\.$email == dto.email)
            .first()
        else {
            throw Abort(.notFound, reason: "Aucun membre avec cet email dans ce foyer.")
        }
        
        // Vérifier s’il est déjà lié
        if membre.$user.id != nil {
            throw Abort(.badRequest, reason: "Ce membre a déjà un compte associé.")
        }
        
        // Associer l'utilisateur
        membre.$user.id = userId
        try await membre.save(on: req.db)
        
        return MembreJoinResponse(
            membreId: try membre.requireID(),
            foyerId: try foyer.requireID()
        )
    }
    
    //GET /membres/foyer/:foyerId
    @Sendable
    func getMembresByFoyer(_ req: Request) async throws -> [MembreDTO] {
        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id

        guard let foyerId = req.parameters.get("foyerId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "foyerId manquant ou invalide.")
        }

        // Vérifier que l'utilisateur a accès à ce foyer (membre ou gestionnaire)
        let aAcces = try await Membre.query(on: req.db)
            .filter(\.$foyer.$id == foyerId)
            .group(.or) { group in
                group.filter(\.$user.$id == userId)
                group.filter(\.$gestionnaire.$id == userId)
            }
            .first() != nil

        guard aAcces else {
            throw Abort(.forbidden, reason: "Vous n'avez pas accès à ce foyer.")
        }

        // Récupérer tous les membres de ce foyer
        let membres = try await Membre.query(on: req.db)
            .filter(\.$foyer.$id == foyerId)
            .all()

        return membres.map { membre in
            MembreDTO(
                id: membre.id,
                estGere: membre.estGere,
                dateEntree: membre.dateEntree,
                nom: membre.nom,
                email: membre.email,
                couleur: membre.couleur,
                avatar: membre.avatar,
                cagnotte: membre.cagnotte,
                niveau: membre.niveau,
                userId: membre.$user.id,
                gestionnaireId: membre.$gestionnaire.id,
                foyerId: membre.$foyer.id
            )
        }
    }

    //GET /membres/geres/:foyerId
    @Sendable
    func getMembresGeres(_ req: Request) async throws -> [MembreDTO] {
        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id

        guard let foyerId = req.parameters.get("foyerId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "foyerId manquant ou invalide.")
        }

        // Uniquement les membres de ce foyer gérés par l'utilisateur connecté
        let membres = try await Membre.query(on: req.db)
            .filter(\.$foyer.$id == foyerId)
            .filter(\.$gestionnaire.$id == userId)
            .all()

        return membres.map { membre in
            MembreDTO(
                id: membre.id,
                estGere: membre.estGere,
                dateEntree: membre.dateEntree,
                nom: membre.nom,
                email: membre.email,
                couleur: membre.couleur,
                avatar: membre.avatar,
                cagnotte: membre.cagnotte,
                niveau: membre.niveau,
                userId: membre.$user.id,
                gestionnaireId: membre.$gestionnaire.id,
                foyerId: membre.$foyer.id
            )
        }
    }

}
