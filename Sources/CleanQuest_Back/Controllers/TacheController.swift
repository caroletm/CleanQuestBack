//
//  TacheController.swift
//  CleanQuest_Back
//
//  Created by caroletm on 13/05/2026.
//

import Vapor
import Fluent

struct TacheController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let taches = routes.grouped("taches")
        let protected = taches.grouped(JWTMiddleware())

        protected.post("categorie", use: createCategorieTache)
        protected.get("categories", use: getCategories)
        protected.get("icones", use: getIcones)
        protected.get("templates", use: getTemplates)
        protected.post(use: createTache)
    }

    // GET /taches/templates — liste les templates, filtrable par ?categorie_id=
    @Sendable
    func getTemplates(_ req: Request) async throws -> [TacheTemplateDTO] {
        var query = TacheTemplate.query(on: req.db)
        if let categorieId = req.query[UUID.self, at: "categorie_id"] {
            query = query.filter(\.$categorie.$id == categorieId)
        }
        let templates = try await query.all()
        return templates.map {
            TacheTemplateDTO(id: $0.id, nom: $0.nom, categorie_id: $0.$categorie.id)
        }
    }

    // POST /taches/categorie — crée une catégorie custom pour le foyer de l'utilisateur
    @Sendable
    func createCategorieTache(_ req: Request) async throws -> CategorieTacheDTO {
        let payload = try req.auth.require(UserPayload.self)
        let dto = try req.content.decode(CategorieTacheDTO.self)

        guard let membre = try await Membre.query(on: req.db)
            .filter(\.$user.$id == payload.id)
            .first() else {
            throw Abort(.notFound, reason: "Membre introuvable")
        }

        let categorieTache = CategorieTache(nom: dto.nom)
        categorieTache.$foyer.id = membre.$foyer.id

        try await categorieTache.save(on: req.db)

        return CategorieTacheDTO(
            id: categorieTache.id,
            nom: categorieTache.nom,
            foyer_id: categorieTache.$foyer.id
        )
    }

    // GET /taches/categories — liste les catégories globales + celles du foyer
    @Sendable
    func getCategories(_ req: Request) async throws -> [CategorieTacheDTO] {
        let payload = try req.auth.require(UserPayload.self)

        guard let membre = try await Membre.query(on: req.db)
            .filter(\.$user.$id == payload.id)
            .first() else {
            throw Abort(.notFound, reason: "Membre introuvable")
        }

        let categories = try await CategorieTache.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$foyer.$id == nil)
                group.filter(\.$foyer.$id == membre.$foyer.id)
            }
            .all()

        return categories.map {
            CategorieTacheDTO(id: $0.id, nom: $0.nom, foyer_id: $0.$foyer.id)
        }
    }

    // GET /taches/icones — liste toutes les icônes disponibles
    @Sendable
    func getIcones(_ req: Request) async throws -> [Icone] {
        return try await Icone.query(on: req.db).all()
    }

    // POST /taches — crée une tâche assignée à une catégorie existante
    @Sendable
    func createTache(_ req: Request) async throws -> Tache {
        let payload = try req.auth.require(UserPayload.self)
        let dto = try req.content.decode(TacheCreateDTO.self)

        guard let membre = try await Membre.query(on: req.db)
            .filter(\.$user.$id == payload.id)
            .first() else {
            throw Abort(.notFound, reason: "Membre introuvable")
        }

        guard let categorie = try await CategorieTache.find(dto.categorie_id, on: req.db) else {
            throw Abort(.notFound, reason: "Catégorie introuvable")
        }

        // Sécurité : la catégorie doit être globale ou appartenir au bon foyer
        if let foyerIdCategorie = categorie.$foyer.id,
           foyerIdCategorie != membre.$foyer.id {
            throw Abort(.forbidden, reason: "Cette catégorie n'appartient pas à votre foyer")
        }

        guard try await Icone.find(dto.icone_id, on: req.db) != nil else {
            throw Abort(.notFound, reason: "Icône introuvable")
        }

        let tache = Tache(
            nom: dto.nom,
            icone_id: dto.icone_id,
            frequence: dto.frequence,
            duree: dto.duree,
            difficulté: dto.difficulte,
            points: dto.points,
            aFaireValider: dto.aFaireValider
        )
        tache.$categorie.id = categorie.id!
        tache.$foyer.id = membre.$foyer.id

        try await tache.save(on: req.db)
        return tache
    }
}
