//
//  FoyerController.swift
//  CleanQuest_Back
//
//  Created by caroletm on 16/04/2026.
//

import Vapor
import Fluent
import JWT

struct FoyerController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let foyers = routes.grouped("foyers")
        let protected = foyers.grouped(JWTMiddleware())
        protected.post(use: createFoyer)
        protected.get(use: getAllFoyers)
    }
    
    
    // POST /foyers
    @Sendable
    func createFoyer(_ req: Request) async throws -> FoyerDTO {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let gestionnaire = try await User.find(payload.id, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur introuvable")
        }
        guard let gestionnaireId = gestionnaire.id else {
            throw Abort(.internalServerError, reason: "ID gestionnaire manquant")
        }
        
        let dto = try req.content.decode(CreateFoyerDTO.self)
        let codeFoyer = String.randomCodeFoyer()
        
        let newFoyer = Foyer(nom: dto.nom, type: dto.type, codeFoyer: codeFoyer)
        
        try await newFoyer.save(on: req.db)
        
        guard let foyerId = newFoyer.id else {
            throw Abort(.internalServerError, reason: "ID foyer manquant")
        }
        
        var membresDTO: [MembreDTO] = []
        
        for createMembreDTO in dto.membres {
            let membre = Membre(
                estGere: createMembreDTO.estGere,
                dateEntree: Date(),
                nom: createMembreDTO.nom,
                email: createMembreDTO.email ?? "",
                couleur: createMembreDTO.couleur,
                avatar: createMembreDTO.avatar
            )
            
            if createMembreDTO.estGere {
                membre.$gestionnaire.id = gestionnaireId
                membre.$user.id = gestionnaireId
            }
            membre.$foyer.id = foyerId
            
            if let userId = createMembreDTO.userId {
                membre.$user.id = userId
            }
            try await membre.save(on: req.db)
            
            membresDTO.append(MembreDTO(
                id: membre.id,
                estGere: membre.estGere,
                dateEntree: membre.dateEntree,
                nom: membre.nom,
                email : membre.email,
                couleur: membre.couleur,
                avatar: membre.avatar,
                cagnotte: membre.cagnotte,
                niveau: membre.niveau,
                userId: createMembreDTO.userId,
                gestionnaireId: gestionnaireId,
                foyerId: foyerId
            ))
        }
        
        //ENVOI DES EMAILS
        for membre in membresDTO.filter({$0.email != nil}) {
            let html = """
            <h2>🧹 Bienvenue dans la communauté CleanQuest\n</h2>
            <p>Bonjour <strong>\(membre.nom)</strong>,</p>
            <p>Tu as été invité.e à rejoindre le foyer :</p>
            <p><strong>\(newFoyer.nom) </strong></p>
            <p>Voici ton code pour rejoindre le foyer :</p>
            <h3 style="color:#d40000;">\(newFoyer.codeFoyer)</h3>
            <p>🧽 Installe l'application avec cette adresse mail et entre ce code pour participer.</p>
            
            """
            
            try await BrevoEmailService.sendEmail(
                req: req,
                to: membre.email ?? "",
                subject: "Rejoins ton foyer CleanQuest",
                html: html)
        }
        
        return FoyerDTO(
            nom: newFoyer.nom, type: newFoyer.type, codeFoyer: newFoyer.codeFoyer, membres: membresDTO)
        
    }
    
    // GET /foyers
    
    @Sendable
    func getAllFoyers(_ req: Request) async throws -> [FoyerDTO] {
        
        let payload = try req.auth.require(UserPayload.self)
        let userId = payload.id
        
        let foyers = try await Foyer.query(on: req.db)
            .join(Membre.self, on: \Membre.$foyer.$id == \Foyer.$id)
            .filter(Membre.self, \.$user.$id == userId)
            .with(\.$membres)
            .all()
        
        return foyers.map { foyer in
            let membresDTO = foyer.membres.map { m in
                MembreDTO(
                    id: m.id,
                    estGere: m.estGere,
                    dateEntree: m.dateEntree,
                    nom: m.nom,
                    email: m.email,
                    couleur: m.couleur,
                    avatar: m.avatar,
                    cagnotte: m.cagnotte,
                    niveau: m.niveau,
                    userId: m.$user.id,
                    gestionnaireId: m.$gestionnaire.id,
                    foyerId: m.$foyer.id
                )
            }
            return FoyerDTO(nom: foyer.nom, type: foyer.type, codeFoyer: foyer.codeFoyer, membres: membresDTO)
        }
    }

    
}
extension String {
    static func randomCodeFoyer(length: Int = 6) -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return String((0..<length).map { _ in chars.randomElement()! })
    }
}
