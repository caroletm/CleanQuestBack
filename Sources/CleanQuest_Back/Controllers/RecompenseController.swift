//
//  RecompenseController.swift
//  CleanQuest_Back
//
//  Created by caroletm on 02/07/2026.
//

import Vapor
import Fluent

struct RecompenseController: RouteCollection {
    func boot(routes : any RoutesBuilder) throws {
        let membres = routes.grouped("recompenses")
        let protected = membres.grouped(JWTMiddleware())
        
        protected.get(use: getRecompenses)
        protected.post("acheter",":foyerId", ":recompenseId",use: acheterRecompense)
    }
    
    // GET /recompenses — catalogue global
    @Sendable
    func getRecompenses(_ req: Request) async throws -> [RecompenseDTO] {
        _ = try req.auth.require(UserPayload.self)
        let recompenses = try await Recompense.query(on: req.db)
            .with(\.$categorie)
            .all()
        return recompenses.map { r in
            RecompenseDTO(
                id: r.id, nom: r.nom, image: r.image, points: r.points,
                descriptionCourte: r.descriptionCourte,
                descriptionLongue: r.descriptionLongue,
                descriptionEnCours: r.descriptionEnCours,
                dureeMinutes: r.dureeMinutes,
                categorie_id: r.$categorie.id,
                categorie_nom: r.categorie.nom
            )
        }
    }
    
    // POST /recompenses/:foyerId/:recompenseId
    @Sendable
    func acheterRecompense(_ req: Request) async throws -> UtilisationRecompenseResponseDTO {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)
        let dto = try req.content.decode(UtilisationRecompenseCreateDTO.self)
        
        guard let recompenseId = req.parameters.get("recompenseId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "recompenseId manquant ou invalide.")
        }
        
        let proprietaire_id = dto.proprietaire_id
        
        let recompenseQuery = Recompense.query(on: req.db)
            .filter(\.$id == recompenseId)
            .with(\.$categorie)
        guard let recompense = try await recompenseQuery.first() else {
            throw Abort(.notFound, reason: "Recompense introuvable")
        }
        
        guard let acheteur = try await Membre.find(dto.proprietaire_id, on: req.db),
              acheteur.$foyer.id == foyerId,
              acheteur.$user.id == payload.id || acheteur.$gestionnaire.id == payload.id
        else {
            throw Abort(.forbidden, reason: "L'acheteur n'appartient pas à votre foyer ou vous n'etes autorisé à acheter que pour vous même ou pour le membre que vous gérez")
        }
        
        let utilisationQuery = UtilisationRecompense.query(on: req.db)
            .filter(\.$proprietaire.$id == dto.proprietaire_id)
            .filter(\.$recompense.$id == recompenseId)
            .filter(\.$statutRecompense ~~ [.achetee, .attribuee, .enCours])
        
        guard try await utilisationQuery.first() == nil else {
            throw Abort(.conflict, reason: "Cette récompense est déjà dans votre portefeuille")
        }
        
        guard acheteur.cagnotte >= recompense.points else {
            throw Abort(.badRequest, reason: "Vous n'avez pas assez de points pour acheter cette récompense")
        }
        
        let utilisationRecompense = UtilisationRecompense(
            id: UUID(),
            statutRecompense: .achetee,
            proprietaireId: proprietaire_id,
            recompenseId: recompenseId)
        
        acheteur.cagnotte -= recompense.points
        
        try await req.db.transaction { db in
            try await utilisationRecompense.save(on: db)
            try await acheteur.save(on: db)
        }
        
        let recompenseDTO = RecompenseDTO(
            id: recompense.id,
            nom: recompense.nom,
            image: recompense.image,
            points: recompense.points,
            descriptionCourte: recompense.descriptionCourte,
            descriptionLongue: recompense.descriptionLongue,
            descriptionEnCours: recompense.descriptionEnCours,
            dureeMinutes: recompense.dureeMinutes,
            categorie_id: recompense.$categorie.id,
            categorie_nom: recompense.categorie.nom)
        
        return UtilisationRecompenseResponseDTO(
            id: utilisationRecompense.id,
            statutRecompense: utilisationRecompense.statutRecompense,
            dateAchat: utilisationRecompense.dateAchat,
            proprietaire_id: utilisationRecompense.$proprietaire.id,
            recompense: recompenseDTO,
            cagnotteProprietaire: acheteur.cagnotte)
    }
    
    // Récupère le foyerId de la route et vérifie que l'utilisateur y a accès (membre ou gestionnaire)
    private func foyerAutorise(_ req: Request, userId: UUID) async throws -> UUID {
        guard let foyerId = req.parameters.get("foyerId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "foyerId manquant ou invalide.")
        }

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
        return foyerId
    }
}
