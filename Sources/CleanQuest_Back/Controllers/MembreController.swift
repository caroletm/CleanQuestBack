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
        protected.post("foyer", ":foyerId", use: addMembreToFoyer)
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

        // Le membre récupère ici le pseudo, l'avatar et la couleur choisis à l'inscription.
        if let nom = dto.nom, !nom.isEmpty {
            membre.nom = nom
        }
        if let couleur = dto.couleur, !couleur.isEmpty {
            membre.couleur = couleur
        }
        if let avatar = dto.avatar, !avatar.isEmpty {
            membre.avatar = avatar
        }

        try await membre.save(on: req.db)
        
        return MembreJoinResponse(
            membreId: try membre.requireID(),
            foyerId: try foyer.requireID()
        )
    }
    
    // POST /membres/foyer/:foyerId
    // Ajoute un membre à un foyer DÉJÀ créé (la création initiale passe par POST /foyers).
    @Sendable
    func addMembreToFoyer(_ req: Request) async throws -> MembreDTO {
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

        guard let foyer = try await Foyer.find(foyerId, on: req.db) else {
            throw Abort(.notFound, reason: "Foyer introuvable.")
        }

        let dto = try req.content.decode(CreateMembreDTO.self)
        let email = dto.email ?? ""

        // joinFoyer retrouve le membre via (foyer + email) : un doublon rendrait la liaison aléatoire.
        if !email.isEmpty {
            let dejaPris = try await Membre.query(on: req.db)
                .filter(\.$foyer.$id == foyerId)
                .filter(\.$email == email)
                .first() != nil

            guard !dejaPris else {
                throw Abort(.conflict, reason: "Un membre avec cet email est déjà dans ce foyer.")
            }
        }

        let membre = Membre(
            estGere: dto.estGere,
            dateEntree: Date(),
            nom: dto.nom,
            email: email,
            couleur: dto.couleur,
            avatar: dto.avatar
        )

        membre.$foyer.id = foyerId

        if dto.estGere {
            membre.$gestionnaire.id = userId
            membre.$user.id = userId
        }

        try await membre.save(on: req.db)

        // Membre non géré : il lui faut le code du foyer pour créer son compte.
        if !dto.estGere && !email.isEmpty {
            do {
                try await BrevoEmailService.sendInvitation(
                    req: req,
                    nom: membre.nom,
                    email: email,
                    foyer: foyer)
            } catch {
                // Le membre est déjà enregistré : un mail raté ne doit pas faire échouer la requête.
                req.logger.error("Invitation non envoyée à \(email) : \(String(reflecting: error))")
            }
        }

        return MembreDTO(
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
            foyerId: membre.$foyer.id,
                estSupprime: membre.estSupprime
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
                foyerId: membre.$foyer.id,
                estSupprime: membre.estSupprime
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

        // Les membres de ce foyer gérés par l'utilisateur connecté + son propre membre
        // (un membre qui a rejoint le foyer n'a pas de gestionnaire, il faut donc aussi chercher par user).
        let membres = try await Membre.query(on: req.db)
            .filter(\.$foyer.$id == foyerId)
            .group(.or) { group in
                group.filter(\.$gestionnaire.$id == userId)
                group.filter(\.$user.$id == userId)
            }
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
                foyerId: membre.$foyer.id,
                estSupprime: membre.estSupprime
            )
        }
    }

}
