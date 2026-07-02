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
                categorie_id: r.$categorie.id,
                categorie_nom: r.categorie.nom
            )
        }
    }
    
    
}
