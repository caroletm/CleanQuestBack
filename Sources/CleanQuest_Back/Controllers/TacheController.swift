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

        protected.post("categorie", ":foyerId", use: createCategorieTache)
        protected.get("categories", ":foyerId", use: getCategories)
        protected.get("icones", use: getIcones)
        protected.get("templates", ":foyerId", use: getTemplates)
        protected.get("occurences", ":foyerId", use: getOccurences)
        protected.post(":foyerId", use: createTache)
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

    // GET /taches/occurences/:foyerId — liste toutes les occurrences des tâches du foyer
    @Sendable
    func getOccurences(_ req: Request) async throws -> [OccurenceTacheDTO] {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)

        let occurences = try await OccurenceTache.query(on: req.db)
            .join(Tache.self, on: \OccurenceTache.$tache.$id == \Tache.$id)
            .filter(Tache.self, \.$foyer.$id == foyerId)
            .with(\.$tache) { $0.with(\.$icone); $0.with(\.$categorie) }
            .all()

        return try occurences.map { occ in
            let tache = occ.tache
            return OccurenceTacheDTO(
                id: occ.id,
                datePlanifiee: occ.datePlanifiee,
                dateRealisee: occ.dateRealisee,
                dateValidee: occ.dateValidee,
                statut: occ.statut,
                realisateur_id: occ.$realisateur.id,
                validateur_id: occ.$validateur.id,
                tache_id: try tache.requireID(),
                tache_nom: tache.nom,
                icone_nomFichier: tache.icone.nomFichier,
                categorie_id: tache.$categorie.id,
                categorie_nom: tache.categorie.nom,
                frequence: tache.frequence,
                duree: tache.duree,
                difficulte: tache.difficulte,
                points: tache.points,
                aFaireValider: tache.aFaireValider
            )
        }
    }

    // GET /taches/templates/:foyerId — liste les templates globaux + ceux du foyer, filtrable par ?categorie_id=
    @Sendable
    func getTemplates(_ req: Request) async throws -> [TacheTemplateDTO] {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)

        var query = TacheTemplate.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$foyer.$id == nil)
                group.filter(\.$foyer.$id == foyerId)
            }
        if let categorieId = req.query[UUID.self, at: "categorie_id"] {
            query = query.filter(\.$categorie.$id == categorieId)
        }
        let templates = try await query.all()
        return templates.map {
            TacheTemplateDTO(
                id: $0.id,
                nom: $0.nom,
                categorie_id: $0.$categorie.id,
                foyer_id: $0.$foyer.id
            )
        }
    }

    // POST /taches/categorie/:foyerId — crée une catégorie custom pour le foyer
    @Sendable
    func createCategorieTache(_ req: Request) async throws -> CategorieTacheDTO {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)
        let dto = try req.content.decode(CategorieTacheDTO.self)

        let categorieTache = CategorieTache(nom: dto.nom)
        categorieTache.$foyer.id = foyerId

        try await categorieTache.save(on: req.db)

        return CategorieTacheDTO(
            id: categorieTache.id,
            nom: categorieTache.nom,
            foyer_id: categorieTache.$foyer.id
        )
    }

    // GET /taches/categories/:foyerId — liste les catégories globales + celles du foyer
    @Sendable
    func getCategories(_ req: Request) async throws -> [CategorieTacheDTO] {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)

        let categories = try await CategorieTache.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$foyer.$id == nil)
                group.filter(\.$foyer.$id == foyerId)
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

    // POST /taches/:foyerId — crée une tâche pour le foyer (catégorie et template créés à la volée si besoin)
    @Sendable
    func createTache(_ req: Request) async throws -> TacheResponseDTO {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)
        let dto = try req.content.decode(TacheCreateDTO.self)

        let nomTache = dto.nom.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nomTache.isEmpty else {
            throw Abort(.badRequest, reason: "Le nom de la tâche est obligatoire")
        }

        guard try await Icone.find(dto.icone_id, on: req.db) != nil else {
            throw Abort(.notFound, reason: "Icône introuvable")
        }

        // Transaction : si une étape échoue, rien n'est sauvegardé
        return try await req.db.transaction { db in

            // 1 - CATÉGORIE (existante ou créée à la volée avec l'UUID du front)
            let categorie: CategorieTache
            if let existing = try await CategorieTache.find(dto.categorie_id, on: db) {
                if let foyerIdCategorie = existing.$foyer.id,
                   foyerIdCategorie != foyerId {
                    throw Abort(.forbidden, reason: "Cette catégorie n'appartient pas à votre foyer")
                }
                categorie = existing
            } else {
                guard let nomCategorie = dto.categorie_nom?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !nomCategorie.isEmpty else {
                    throw Abort(.badRequest, reason: "Le nom de la catégorie est obligatoire pour en créer une nouvelle")
                }
                let newCategorie = CategorieTache(id: dto.categorie_id, nom: nomCategorie)
                newCategorie.$foyer.id = foyerId
                try await newCategorie.save(on: db)
                categorie = newCategorie
            }
            let categorieId = try categorie.requireID()

            // 2 - TACHE TEMPLATE (nom réutilisable) — créé si l'UUID du front n'existe pas encore
            if let templateId = dto.tache_template_id {
                if let existingTemplate = try await TacheTemplate.find(templateId, on: db) {
                    if let foyerIdTemplate = existingTemplate.$foyer.id,
                       foyerIdTemplate != foyerId {
                        throw Abort(.forbidden, reason: "Ce template n'appartient pas à votre foyer")
                    }
                } else {
                    let newTemplate = TacheTemplate(
                        id: templateId,
                        nom: nomTache,
                        categorieId: categorieId,
                        foyerId: foyerId
                    )
                    try await newTemplate.save(on: db)
                }
            }

            // 3 - TACHE (instance concrète liée au foyer)
            let tache = Tache(
                id: dto.id,
                nom: nomTache,
                icone_id: dto.icone_id,
                frequence: dto.frequence,
                duree: dto.duree,
                difficulte: dto.difficulte,
                points: dto.points,
                aFaireValider: dto.aFaireValider
            )
            tache.$categorie.id = categorieId
            tache.$foyer.id = foyerId

            try await tache.save(on: db)

            // 4 - OCCURENCE TACHE (1ère occurrence à l'échéance, non assignée)
            let occurence = OccurenceTache(
                datePlanifiee: dto.date_echeance,
                statut: .aFaire,
                tacheId: try tache.requireID()
            )
            try await occurence.save(on: db)

            return TacheResponseDTO(
                id: tache.id,
                nom: tache.nom,
                categorie_id: tache.$categorie.id,
                foyer_id: tache.$foyer.id,
                icone_id: tache.$icone.id,
                frequence: tache.frequence,
                duree: tache.duree,
                difficulte: tache.difficulte,
                points: tache.points,
                aFaireValider: tache.aFaireValider,
                dateCreation: tache.dateCreation
            )
        }
    }
}
