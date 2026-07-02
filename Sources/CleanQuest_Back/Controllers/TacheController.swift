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
        protected.patch(":foyerId", ":tacheId", use: updateTache)
        protected.post("occurences", "valider-simple", ":foyerId", ":occurenceId", use: validerTacheSimple)
        protected.post("occurences", "declarer-realisee", ":foyerId", ":occurenceId", use: declarerTacheRealisee)
        protected.post("occurences", "valider", ":foyerId", ":occurenceId", use: validerTache)
        protected.post("occurences", "refuser", ":foyerId", ":occurenceId", use: refuserTache)
        protected.delete(":foyerId", ":tacheId", use: deleteTache)
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

            // 2 - TACHE TEMPLATE (nom réutilisable) — réutilise ou crée à la volée
            if let providedId = dto.tache_template_id,
               let existingTemplate = try await TacheTemplate.find(providedId, on: db) {
                // Cas 1 : front a fourni un ID qui existe → on vérifie le foyer
                if let foyerIdTemplate = existingTemplate.$foyer.id,
                   foyerIdTemplate != foyerId {
                    throw Abort(.forbidden, reason: "Ce template n'appartient pas à votre foyer")
                }
                // rien à faire : on réutilise le template fourni
            } else if let existingByName = try await TacheTemplate.query(on: db)
                .filter(\.$foyer.$id == foyerId)
                .filter(\.$nom == nomTache)
                .filter(\.$categorie.$id == categorieId)
                .first() {
                // Cas 2 : un template avec le même nom existe déjà dans ce foyer → on le réutilise
                _ = try existingByName.requireID()
            } else {
                // Cas 3 : pas trouvé → on crée
                let newTemplate = TacheTemplate(
                    id: dto.tache_template_id ?? UUID(),
                    nom: nomTache,
                    categorieId: categorieId,
                    foyerId: foyerId
                )
                try await newTemplate.save(on: db)
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

            // 4 - OCCURRENCES — 1ère à l'échéance, puis fenêtre de 30 jours selon la fréquence
            let premiereOccurence = OccurenceTache(
                datePlanifiee: dto.date_echeance,
                statut: .aFaire,
                tacheId: try tache.requireID()
            )
            try await premiereOccurence.save(on: db)

            let calendar = OccurrenceGenerator.calendrier()
            let finFenetre = calendar.date(
                byAdding: .day,
                value: OccurrenceGenerator.fenetreJours,
                to: dto.date_echeance
            ) ?? dto.date_echeance
            try await OccurrenceGenerator.genererOccurrences(
                pour: tache,
                ancre: dto.date_echeance,
                jusqua: finFenetre,
                on: db
            )

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

 
    // PATCH /taches/:foyerId/:tacheId — modifie les champs de la tâche ; un changement de fréquence régénère les occurrences futures
    @Sendable
    func updateTache(_ req: Request) async throws -> TacheResponseDTO {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)

        guard let tacheId = req.parameters.get("tacheId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "tacheId manquant ou invalide.")
        }
        guard let tache = try await Tache.find(tacheId, on: req.db) else {
            throw Abort(.notFound, reason: "Tâche introuvable")
        }
        guard tache.$foyer.id == foyerId else {
            throw Abort(.forbidden, reason: "Cette tâche n'appartient pas à votre foyer")
        }

        let dto = try req.content.decode(TacheUpdateDTO.self)
        let ancienneFrequence = tache.frequence

        if let nom = dto.nom {
            let nomTrim = nom.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !nomTrim.isEmpty else {
                throw Abort(.badRequest, reason: "Le nom de la tâche ne peut pas être vide")
            }
            tache.nom = nomTrim
        }
        if let iconeId = dto.icone_id {
            guard try await Icone.find(iconeId, on: req.db) != nil else {
                throw Abort(.notFound, reason: "Icône introuvable")
            }
            tache.$icone.id = iconeId
        }
        if let categorieId = dto.categorie_id {
            guard let categorie = try await CategorieTache.find(categorieId, on: req.db) else {
                throw Abort(.notFound, reason: "Catégorie introuvable")
            }
            if let foyerIdCategorie = categorie.$foyer.id, foyerIdCategorie != foyerId {
                throw Abort(.forbidden, reason: "Cette catégorie n'appartient pas à votre foyer")
            }
            tache.$categorie.id = categorieId
        }
        if let frequence = dto.frequence { tache.frequence = frequence }
        if let duree = dto.duree { tache.duree = duree }
        if let difficulte = dto.difficulte { tache.difficulte = difficulte }
        if let points = dto.points { tache.points = points }
        if let aFaireValider = dto.aFaireValider { tache.aFaireValider = aFaireValider }

        let frequenceChangee = dto.frequence != nil && dto.frequence != ancienneFrequence

        try await req.db.transaction { db in
            try await tache.save(on: db)

            guard frequenceChangee else { return }

            let maintenant = Date()

            // Ancre = plus ancienne occurrence (approximation de l'échéance d'origine),
            // capturée avant suppression pour garder la phase de la nouvelle série.
            let ancre = try await OccurenceTache.query(on: db)
                .filter(\.$tache.$id == tacheId)
                .sort(\.$datePlanifiee, .ascending)
                .first()?
                .datePlanifiee ?? maintenant

            // Supprime les occurrences futures encore "à faire" ; l'historique
            // (passé + faites/validées) est préservé.
            try await OccurenceTache.query(on: db)
                .filter(\.$tache.$id == tacheId)
                .filter(\.$datePlanifiee > maintenant)
                .filter(\.$statut == .aFaire)
                .delete()

            // Régénère le futur selon la nouvelle fréquence.
            let calendar = OccurrenceGenerator.calendrier()
            let finFenetre = calendar.date(
                byAdding: .day,
                value: OccurrenceGenerator.fenetreJours,
                to: maintenant
            ) ?? maintenant
            try await OccurrenceGenerator.genererOccurrences(
                pour: tache,
                ancre: ancre,
                jusqua: finFenetre,
                apartir: maintenant,
                on: db
            )
        }

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

    // POST /taches/occurences/valider-simple/:foyerId/:occurenceId — valide une occurrence de tâche simple (sans étape de validation par un tiers)
    @Sendable
    func validerTacheSimple(_ req: Request) async throws -> OccurenceTacheDTO {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)

        guard let occurenceId = req.parameters.get("occurenceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "occurenceId manquant ou invalide.")
        }
        let dto = try req.content.decode(OccurenceTacheValidationDTO.self)

        let occurenceQuery = OccurenceTache.query(on: req.db)
            .filter(\.$id == occurenceId)
            .with(\.$tache) { $0.with(\.$icone); $0.with(\.$categorie) }
        guard let occurence = try await occurenceQuery.first() else {
            throw Abort(.notFound, reason: "Occurrence introuvable")
        }
        guard occurence.tache.$foyer.id == foyerId else {
            throw Abort(.forbidden, reason: "Cette occurrence n'appartient pas à votre foyer")
        }
        guard occurence.tache.aFaireValider == false else {
            throw Abort(.badRequest, reason: "Cette tâche nécessite une validation par un autre membre")
        }

        guard let realisateur = try await Membre.find(dto.realisateur_id, on: req.db),
              realisateur.$foyer.id == foyerId else {
            throw Abort(.forbidden, reason: "Le réalisateur n'appartient pas à votre foyer")
        }
        let realisateurId = try realisateur.requireID()

        let validateurId: UUID
        if dto.validateur_id == dto.realisateur_id {
            validateurId = realisateurId
        } else {
            guard let validateur = try await Membre.find(dto.validateur_id, on: req.db),
                  validateur.$foyer.id == foyerId else {
                throw Abort(.forbidden, reason: "Le validateur n'appartient pas à votre foyer")
            }
            validateurId = try validateur.requireID()
        }

        let maintenant = Date()
        occurence.dateRealisee = maintenant
        occurence.dateValidee = maintenant
        occurence.statut = .validee
        occurence.$realisateur.id = realisateurId
        occurence.$validateur.id = validateurId

        realisateur.cagnotte += occurence.tache.points

        try await req.db.transaction { db in
            try await occurence.save(on: db)
            try await realisateur.save(on: db)
        }

        let tache = occurence.tache
        return OccurenceTacheDTO(
            id: occurence.id,
            datePlanifiee: occurence.datePlanifiee,
            dateRealisee: occurence.dateRealisee,
            dateValidee: occurence.dateValidee,
            statut: occurence.statut,
            realisateur_id: occurence.$realisateur.id,
            validateur_id: occurence.$validateur.id,
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

    // POST /taches/occurences/declarer-realisee/:foyerId/:occurenceId — déclare qu'une tâche à valider a été réalisée (statut en attente de validation par un tiers)
    @Sendable
    func declarerTacheRealisee(_ req: Request) async throws -> OccurenceTacheDTO {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)

        guard let occurenceId = req.parameters.get("occurenceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "occurenceId manquant ou invalide.")
        }
        let dto = try req.content.decode(OccurenceTacheRealisationDTO.self)

        let occurenceQuery = OccurenceTache.query(on: req.db)
            .filter(\.$id == occurenceId)
            .with(\.$tache) { $0.with(\.$icone); $0.with(\.$categorie) }
        guard let occurence = try await occurenceQuery.first() else {
            throw Abort(.notFound, reason: "Occurrence introuvable")
        }
        guard occurence.tache.$foyer.id == foyerId else {
            throw Abort(.forbidden, reason: "Cette occurrence n'appartient pas à votre foyer")
        }
        guard occurence.tache.aFaireValider == true else {
            throw Abort(.badRequest, reason: "Cette tâche ne nécessite pas de validation par un tiers ; utilisez /valider-simple")
        }

        guard let realisateur = try await Membre.find(dto.realisateur_id, on: req.db),
              realisateur.$foyer.id == foyerId else {
            throw Abort(.forbidden, reason: "Le réalisateur n'appartient pas à votre foyer")
        }
        let realisateurId = try realisateur.requireID()

        occurence.dateRealisee = Date()
        occurence.statut = .enAttenteDeValidation
        occurence.$realisateur.id = realisateurId

        try await occurence.save(on: req.db)

        let tache = occurence.tache
        return OccurenceTacheDTO(
            id: occurence.id,
            datePlanifiee: occurence.datePlanifiee,
            dateRealisee: occurence.dateRealisee,
            dateValidee: occurence.dateValidee,
            statut: occurence.statut,
            realisateur_id: occurence.$realisateur.id,
            validateur_id: occurence.$validateur.id,
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
    
    // POST /taches/occurences/valider/:foyerId/:occurenceId — valide une occurrence de tâche "à faire valider" (validation par un autre membre du foyer)
    @Sendable
    func validerTache(_ req: Request) async throws -> OccurenceTacheDTO {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)

        guard let occurenceId = req.parameters.get("occurenceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "occurenceId manquant ou invalide.")
        }
        let dto = try req.content.decode(OccurenceTacheValidationDTO.self)

        let occurenceQuery = OccurenceTache.query(on: req.db)
            .filter(\.$id == occurenceId)
            .with(\.$tache) { $0.with(\.$icone); $0.with(\.$categorie) }
        guard let occurence = try await occurenceQuery.first() else {
            throw Abort(.notFound, reason: "Occurrence introuvable")
        }
        guard occurence.tache.$foyer.id == foyerId else {
            throw Abort(.forbidden, reason: "Cette occurrence n'appartient pas à votre foyer")
        }
        guard occurence.tache.aFaireValider == true else {
            throw Abort(.badRequest, reason: "Cette tâche ne nécessite pas de validation par un autre membre")
        }

        // Le réalisateur ne peut pas valider sa propre tâche
        guard dto.validateur_id != dto.realisateur_id else {
            throw Abort(.badRequest, reason: "Le réalisateur ne peut pas valider sa propre tâche")
        }

        guard let realisateur = try await Membre.find(dto.realisateur_id, on: req.db),
              realisateur.$foyer.id == foyerId else {
            throw Abort(.forbidden, reason: "Le réalisateur n'appartient pas à votre foyer")
        }
        let realisateurId = try realisateur.requireID()

        guard let validateur = try await Membre.find(dto.validateur_id, on: req.db),
              validateur.$foyer.id == foyerId else {
            throw Abort(.forbidden, reason: "Le validateur n'appartient pas à votre foyer")
        }
        let validateurId = try validateur.requireID()

        let maintenant = Date()
        // La tâche a déjà été réalisée avant : on garde sa date de réalisation si elle existe
        if occurence.dateRealisee == nil {
            occurence.dateRealisee = maintenant
        }
        occurence.dateValidee = maintenant
        occurence.statut = .validee
        occurence.$realisateur.id = realisateurId
        occurence.$validateur.id = validateurId

        realisateur.cagnotte += occurence.tache.points

        try await req.db.transaction { db in
            try await occurence.save(on: db)
            try await realisateur.save(on: db)
        }

        let tache = occurence.tache
        return OccurenceTacheDTO(
            id: occurence.id,
            datePlanifiee: occurence.datePlanifiee,
            dateRealisee: occurence.dateRealisee,
            dateValidee: occurence.dateValidee,
            statut: occurence.statut,
            realisateur_id: occurence.$realisateur.id,
            validateur_id: occurence.$validateur.id,
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
    
    // POST /taches/occurences/refuser/:foyerId/:occurenceId — refuse la validation : la tâche est marquée "non validée"
    func refuserTache(_ req: Request) async throws -> OccurenceTacheDTO {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)

        guard let occurenceId = req.parameters.get("occurenceId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "occurenceId manquant ou invalide.")
        }

        let occurenceQuery = OccurenceTache.query(on: req.db)
            .filter(\.$id == occurenceId)
            .with(\.$tache) { $0.with(\.$icone); $0.with(\.$categorie) }
        guard let occurence = try await occurenceQuery.first() else {
            throw Abort(.notFound, reason: "Occurrence introuvable")
        }
        guard occurence.tache.$foyer.id == foyerId else {
            throw Abort(.forbidden, reason: "Cette occurrence n'appartient pas à votre foyer")
        }
        guard occurence.tache.aFaireValider == true else {
            throw Abort(.badRequest, reason: "Cette tâche ne nécessite pas de validation")
        }
        guard occurence.statut == .enAttenteDeValidation || occurence.statut == .nonValidee else {
            throw Abort(.badRequest, reason: "Cette tâche n'est pas en attente de validation")
        }

        // On GARDE le réalisateur et la date pour afficher qui l'avait faite.
        occurence.statut = .nonValidee

        try await occurence.save(on: req.db)

        let tache = occurence.tache
        return OccurenceTacheDTO(
            id: occurence.id,
            datePlanifiee: occurence.datePlanifiee,
            dateRealisee: occurence.dateRealisee,
            dateValidee: occurence.dateValidee,
            statut: occurence.statut,
            realisateur_id: occurence.$realisateur.id,
            validateur_id: occurence.$validateur.id,
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

    // DELETE /taches/:foyerId/:tacheId — supprime la tâche et toutes ses occurrences
    @Sendable
    func deleteTache(_ req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)

        guard let tacheId = req.parameters.get("tacheId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "tacheId manquant ou invalide.")
        }
        guard let tache = try await Tache.find(tacheId, on: req.db) else {
            throw Abort(.notFound, reason: "Tâche introuvable")
        }
        guard tache.$foyer.id == foyerId else {
            throw Abort(.forbidden, reason: "Cette tâche n'appartient pas à votre foyer")
        }

        try await req.db.transaction { db in
            try await OccurenceTache.query(on: db)
                .filter(\.$tache.$id == tacheId)
                .delete()
            try await tache.delete(on: db)
        }

        return .noContent
    }
}

