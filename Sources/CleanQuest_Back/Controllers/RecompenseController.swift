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
        protected.post("utiliser", ":foyerId", ":utilisationId", use: utiliserRecompense)
        protected.post("valider", ":foyerId", ":utilisationId", use: validerUtilisation)
        protected.post("refuser", ":foyerId", ":utilisationId", use: refuserUtilisation)
        protected.post("attribuer", ":foyerId", ":utilisationId", use: attribuerRecompense)
        protected.post("accepter", ":foyerId", ":utilisationId", use: accepterMission)
        protected.post("decliner", ":foyerId", ":utilisationId", use: declinerMission)
        protected.get("tableau", ":foyerId", ":membreId", use: getTableauRecompenses)
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
    func acheterRecompense(_ req: Request) async throws -> EtatRecompensesDTO {
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
        
        let utilisationDTO = UtilisationRecompenseResponseDTO(
            id: utilisationRecompense.id,
            statutRecompense: utilisationRecompense.statutRecompense,
            dateAchat: utilisationRecompense.dateAchat,
            proprietaire_id: utilisationRecompense.$proprietaire.id,
            recompense: recompenseDTO,
            cagnotteProprietaire: acheteur.cagnotte)

        return try await etatRecompenses(utilisationDTO, de: acheteur, foyerId: foyerId, on: req.db)
    }
    
    // POST /recompenses/utiliser/:foyerId/:utilisationId — active une carte du portefeuille
    @Sendable
    func utiliserRecompense(_ req: Request) async throws -> EtatRecompensesDTO {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)
        
        guard let utilisationId = req.parameters.get("utilisationId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "utilisationId manquant ou invalide.")
        }
        
        guard let utilisation = try await UtilisationRecompense.query(on: req.db)
            .filter(\.$id == utilisationId)
            .with(\.$proprietaire)
            .with(\.$recompense, { recompense in
                recompense.with(\.$categorie)
            }).first() else {
            throw Abort(.notFound, reason: "Cette carte n'existe pas.")
        }
        
        let proprietaire = utilisation.proprietaire
        guard proprietaire.$foyer.id == foyerId,
              proprietaire.$user.id == payload.id || proprietaire.$gestionnaire.id == payload.id else {
            throw Abort(.forbidden, reason: "Cette carte ne vous appartient pas.")
        }
        
        guard utilisation.statutRecompense == .achetee else {
            throw Abort(.conflict, reason: "Cette carte a deja ete utilisee.")
        }
        
        let maintenant = Date()
        utilisation.statutRecompense = .enCours
        utilisation.dateUtilisation = maintenant
        utilisation.deadline = maintenant.addingTimeInterval(Double(utilisation.recompense.dureeMinutes) * 60)
        
        try await utilisation.save(on: req.db)
        
        let utilisationDTO = utilisation.toResponseDTO(cagnotteProprietaire: proprietaire.cagnotte)
        return try await etatRecompenses(utilisationDTO, de: proprietaire, foyerId: foyerId, on: req.db)
    }
    
    // POST /recompenses/valider/:foyerId/:utilisationId
    @Sendable
    func validerUtilisation(_ req: Request) async throws -> EtatRecompensesDTO {
        try await cloturerUtilisation(req, statut: .validee)
    }
    
    // POST /recompenses/refuser/:foyerId/:utilisationId
    @Sendable
    func refuserUtilisation(_ req: Request) async throws -> EtatRecompensesDTO {
        try await cloturerUtilisation(req, statut: .nonValidee)
    }
    
    // Fin de vie d'une carte : .enCours / .attribuee -> .validee ou .nonValidee
    private func cloturerUtilisation(_ req: Request, statut: StatutRecompense) async throws -> EtatRecompensesDTO {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)
        
        guard let utilisationId = req.parameters.get("utilisationId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "utilisationId manquant ou invalide.")
        }
        
        guard let utilisation = try await UtilisationRecompense.query(on: req.db)
            .filter(\.$id == utilisationId)
            .with(\.$proprietaire)
            .with(\.$destinataire)
            .with(\.$recompense, { recompense in
                recompense.with(\.$categorie)
            }).first() else {
            throw Abort(.notFound, reason: "Cette carte n'existe pas.")
        }
        
        // Seul le propriétaire juge : il a payé la carte, et des points sont en jeu.
        let proprietaire = utilisation.proprietaire
        guard proprietaire.$foyer.id == foyerId,
              proprietaire.$user.id == payload.id || proprietaire.$gestionnaire.id == payload.id else {
            throw Abort(.forbidden, reason: "Seul le propriétaire de la carte peut la clôturer.")
        }
        
        guard utilisation.statutRecompense == .enCours || utilisation.statutRecompense == .attribuee else {
            throw Abort(.conflict, reason: "Cette carte n'est pas en cours.")
        }
        
        utilisation.statutRecompense = statut
        
        // Carte action : le destinataire gagne la moitié des points s'il a fait
        // l'action, et la perd sinon. Un privilège n'a pas de destinataire.
        let destinataire = utilisation.destinataire
        let demiPoints = utilisation.recompense.points / 2
        
        try await req.db.transaction { db in
            try await utilisation.save(on: db)
            
            if let destinataire {
                if statut == .validee {
                    destinataire.cagnotte += demiPoints
                } else {
                    destinataire.cagnotte = max(0, destinataire.cagnotte - demiPoints)
                }
                try await destinataire.save(on: db)
            }
        }

        if let destinataire, let userId = destinataire.$user.id, userId != payload.id {
            let valide = statut == .validee
            await PushService.envoyer(
                a: userId,
                titre: valide ? "✅ \(proprietaire.nom) a confirmé ton action" : "❌ \(proprietaire.nom) n'a pas validé ton action",
                message: "\(utilisation.recompense.nom) : \(valide ? "+" : "-")\(Int(demiPoints)) points",
                on: req)
        }
        
        let utilisationDTO = utilisation.toResponseDTO(cagnotteProprietaire: proprietaire.cagnotte)
        return try await etatRecompenses(utilisationDTO, de: proprietaire, foyerId: foyerId, on: req.db)
    }
    
    // POST /recompenses/attribuer/:foyerId/:utilisationId — donne une carte action à un membre
    @Sendable
    func attribuerRecompense(_ req: Request) async throws -> EtatRecompensesDTO {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)
        let dto = try req.content.decode(AttributionRecompenseDTO.self)

        guard let utilisationId = req.parameters.get("utilisationId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "utilisationId manquant ou invalide.")
        }

        guard let utilisation = try await UtilisationRecompense.query(on: req.db)
            .filter(\.$id == utilisationId)
            .with(\.$proprietaire)
            .with(\.$recompense, { recompense in
                recompense.with(\.$categorie)
            }).first() else {
            throw Abort(.notFound, reason: "Cette carte n'existe pas.")
        }

        let proprietaire = utilisation.proprietaire
        guard proprietaire.$foyer.id == foyerId,
              proprietaire.$user.id == payload.id || proprietaire.$gestionnaire.id == payload.id else {
            throw Abort(.forbidden, reason: "Cette carte ne vous appartient pas.")
        }

        guard utilisation.recompense.categorie.nom == "action" else {
            throw Abort(.badRequest, reason: "Seule une carte action peut être attribuée à un membre.")
        }

        guard utilisation.statutRecompense == .achetee else {
            throw Abort(.conflict, reason: "Cette carte a déjà été utilisée.")
        }

        guard dto.destinataire_id != proprietaire.id else {
            throw Abort(.badRequest, reason: "Vous ne pouvez pas vous attribuer votre propre carte.")
        }

        guard let destinataire = try await Membre.find(dto.destinataire_id, on: req.db),
              destinataire.$foyer.id == foyerId else {
            throw Abort(.badRequest, reason: "Ce membre n'appartient pas à votre foyer.")
        }

        guard !destinataire.estSupprime else {
            throw Abort(.badRequest, reason: "Ce membre a quitté CleanQuest.")
        }

        let maintenant = Date()
        utilisation.statutRecompense = .attribuee
        utilisation.$destinataire.id = try destinataire.requireID()
        utilisation.dateUtilisation = maintenant
        utilisation.deadline = maintenant.addingTimeInterval(Double(utilisation.recompense.dureeMinutes) * 60)

        try await utilisation.save(on: req.db)

        if let destinataireUserId = destinataire.$user.id {
            await PushService.envoyer(
                a: destinataireUserId,
                titre: "\(proprietaire.nom) t'a envoyé une action",
                message: "\(utilisation.recompense.nom) : rends-lui service pour gagner \(Int(utilisation.recompense.points / 2)) points",
                notifId: "mission-\(utilisationId)",
                on: req)
        }

        let utilisationDTO = utilisation.toResponseDTO(cagnotteProprietaire: proprietaire.cagnotte)
        return try await etatRecompenses(utilisationDTO, de: proprietaire, foyerId: foyerId, on: req.db)
    }
    

    // POST /recompenses/accepter/:foyerId/:utilisationId — le destinataire s'engage
    @Sendable
    func accepterMission(_ req: Request) async throws -> EtatRecompensesDTO {
        try await repondreMission(req, accepte: true)
    }

    // POST /recompenses/decliner/:foyerId/:utilisationId — le destinataire refuse la mission
    @Sendable
    func declinerMission(_ req: Request) async throws -> EtatRecompensesDTO {
        try await repondreMission(req, accepte: false)
    }

    // Réponse du DESTINATAIRE à une mission reçue.
    // À ne pas confondre avec cloturerUtilisation, qui est la décision du PROPRIÉTAIRE
    // une fois la deadline passée : autorisation inversée, et statuts de départ différents.
    private func repondreMission(_ req: Request, accepte: Bool) async throws -> EtatRecompensesDTO {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)

        guard let utilisationId = req.parameters.get("utilisationId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "utilisationId manquant ou invalide.")
        }

        guard let utilisation = try await UtilisationRecompense.query(on: req.db)
            .filter(\.$id == utilisationId)
            .with(\.$proprietaire)
            .with(\.$destinataire)
            .with(\.$recompense, { recompense in
                recompense.with(\.$categorie)
            }).first() else {
            throw Abort(.notFound, reason: "Cette mission n'existe pas.")
        }

        // Seul le destinataire répond à sa propre mission : c'est ce qui empêche
        // le propriétaire de s'auto-accepter une carte, et l'inverse.
        guard let destinataire = utilisation.destinataire,
              destinataire.$foyer.id == foyerId,
              destinataire.$user.id == payload.id || destinataire.$gestionnaire.id == payload.id else {
            throw Abort(.forbidden, reason: "Cette mission ne vous est pas destinée.")
        }

        guard utilisation.statutRecompense == .attribuee else {
            throw Abort(.conflict, reason: "Vous avez déjà répondu à cette mission.")
        }

        // Le délai écoulé, il n'y a plus rien à accepter ni à refuser :
        // c'est au propriétaire de trancher.
        guard let deadline = utilisation.deadline, deadline > Date() else {
            throw Abort(.conflict, reason: "Le délai de cette mission est écoulé.")
        }

        if accepte {
            utilisation.statutRecompense = .enCours
            try await utilisation.save(on: req.db)
        } else {
            // Refus : la carte est close tout de suite et le destinataire perd
            // la moitié des points, sans attendre la deadline.
            utilisation.statutRecompense = .nonValidee
            let demiPoints = utilisation.recompense.points / 2
            destinataire.cagnotte = max(0, destinataire.cagnotte - demiPoints)

            try await req.db.transaction { db in
                try await utilisation.save(on: db)
                try await destinataire.save(on: db)
            }
        }

        if let userId = utilisation.proprietaire.$user.id, userId != payload.id {
            await PushService.envoyer(
                a: userId,
                titre: accepte ? "✅ \(destinataire.nom) a accepté ton action" : "❌ \(destinataire.nom) a décliné ton action",
                message: accepte ? "\(utilisation.recompense.nom) est en cours" : "\(utilisation.recompense.nom) ne sera pas réalisée",
                on: req)
        }

        let utilisationDTO = utilisation.toResponseDTO(cagnotteProprietaire: utilisation.proprietaire.cagnotte)
        return try await etatRecompenses(utilisationDTO, de: destinataire, foyerId: foyerId, on: req.db)
    }

    

    // GET /recompenses/tableau/:foyerId/:membreId — tout l'onglet Récompenses en un seul appel
    @Sendable
    func getTableauRecompenses(_ req: Request) async throws -> TableauRecompensesDTO {
        let payload = try req.auth.require(UserPayload.self)
        let foyerId = try await foyerAutorise(req, userId: payload.id)
        let membre = try await membreConsultable(req, foyerId: foyerId, userId: payload.id,
                                                 raison: "Vous ne pouvez consulter que vos récompenses ou celles du membre que vous gérez")

        return try await tableau(de: membre, foyerId: foyerId, on: req.db)
    }

    private func tableau(de membre: Membre, foyerId: UUID, on db: any Database) async throws -> TableauRecompensesDTO {
        TableauRecompensesDTO(
            achetees: try await cartesAchetees(de: membre, on: db),
            missions: try await missions(de: membre, on: db),
            enCours: try await cartesEnCours(foyerId: foyerId, on: db),
            nombreUtilisees: try await nombreUtilisees(foyerId: foyerId, on: db)
        )
    }

    // Carte modifiée + tableau du membre + membres à jour, renvoyés par les routes d'action : évite deux GET côté app
    private func etatRecompenses(_ utilisation: UtilisationRecompenseResponseDTO, de membre: Membre, foyerId: UUID, on db: any Database) async throws -> EtatRecompensesDTO {
        let membres = try await Membre.query(on: db)
            .filter(\.$foyer.$id == foyerId)
            .all()

        return EtatRecompensesDTO(
            utilisation: utilisation,
            tableau: try await tableau(de: membre, foyerId: foyerId, on: db),
            membres: membres.map { $0.toDTO() }
        )
    }

    //MARK: - REQUETES DU TABLEAU

    // Le membre de la route, s'il appartient au foyer et que l'utilisateur est lui-même ou son gestionnaire
    private func membreConsultable(_ req: Request, foyerId: UUID, userId: UUID, raison: String) async throws -> Membre {
        guard let membreId = req.parameters.get("membreId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "membreId manquant ou invalide.")
        }
        guard let membre = try await Membre.find(membreId, on: req.db),
              membre.$foyer.id == foyerId,
              membre.$user.id == userId || membre.$gestionnaire.id == userId else {
            throw Abort(.forbidden, reason: raison)
        }
        return membre
    }

    private func cartesAchetees(de membre: Membre, on db: any Database) async throws -> [UtilisationRecompenseResponseDTO] {
        let membreId = try membre.requireID()
        let utilisations = try await UtilisationRecompense.query(on: db)
            .filter(\.$proprietaire.$id == membreId)
            .filter(\.$statutRecompense ~~ [.achetee, .attribuee, .enCours])
            .with(\.$recompense) { recompense in
                recompense.with(\.$categorie)
            }.all()
        return utilisations.map { $0.toResponseDTO(cagnotteProprietaire: membre.cagnotte) }
    }

    private func missions(de membre: Membre, on db: any Database) async throws -> [UtilisationRecompenseResponseDTO] {
        let membreId = try membre.requireID()
        let utilisations = try await UtilisationRecompense.query(on: db)
            .filter(\.$destinataire.$id == membreId)
            .filter(\.$statutRecompense ~~ [.attribuee, .enCours])
            .with(\.$proprietaire)
            .with(\.$recompense) { recompense in
                recompense.with(\.$categorie)
            }.all()
        return utilisations.map { $0.toResponseDTO(cagnotteProprietaire: $0.proprietaire.cagnotte) }
    }

    // UtilisationRecompense ne porte pas de foyer_id : on passe par les membres.
    private func membreIdsDuFoyer(_ foyerId: UUID, on db: any Database) async throws -> [UUID] {
        let membres = try await Membre.query(on: db)
            .filter(\.$foyer.$id == foyerId)
            .all()
        return try membres.map { try $0.requireID() }
    }

    private func cartesEnCours(foyerId: UUID, on db: any Database) async throws -> [UtilisationRecompenseResponseDTO] {
        let membreIds = try await membreIdsDuFoyer(foyerId, on: db)
        guard !membreIds.isEmpty else { return [] }

        let utilisations = try await UtilisationRecompense.query(on: db)
            .filter(\.$proprietaire.$id ~~ membreIds)
            .filter(\.$statutRecompense ~~ [.attribuee, .enCours])
            .filter(\.$deadline > Date())
            .sort(\.$deadline, .ascending)
            .with(\.$proprietaire)
            .with(\.$recompense) { recompense in
                recompense.with(\.$categorie)
            }.all()
        return utilisations.map { $0.toResponseDTO(cagnotteProprietaire: $0.proprietaire.cagnotte) }
    }

    private func nombreUtilisees(foyerId: UUID, on db: any Database) async throws -> Int {
        let membreIds = try await membreIdsDuFoyer(foyerId, on: db)
        guard !membreIds.isEmpty else { return 0 }

        return try await UtilisationRecompense.query(on: db)
            .filter(\.$proprietaire.$id ~~ membreIds)
            .filter(\.$statutRecompense ~~ [.validee, .nonValidee])
            .count()
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

