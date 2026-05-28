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
        protected.get("foyer", use: getMembresByFoyer)
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
    
    //GET /membres/foyer
    @Sendable
    func getMembresByFoyer(_ req: Request) async throws -> [MembreDTO] {
        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id

        // Trouver le membre lié à l'utilisateur connecté pour récupérer son foyer
        let membreUtilisateur = try await Membre.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$user.$id == userId)
                group.filter(\.$gestionnaire.$id == userId)
            }
            .first()

        guard let membreUtilisateur else {
            throw Abort(.notFound, reason: "Aucun foyer associé à cet utilisateur.")
        }

        let foyerId = membreUtilisateur.$foyer.id

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
                foyerId: foyerId
            )
        }
    }
    
    @Sendable
    func getAllUsers(req: Request) async throws -> [UserDTO] {
        let users: [User] = try await User.query(on: req.db).all()
        
        return users.map { user in
            UserDTO(
                id: user.id,
                name: user.nom,
                email: user.email,
                firstConnection: user.onboarding)
        }
    }
    
}
