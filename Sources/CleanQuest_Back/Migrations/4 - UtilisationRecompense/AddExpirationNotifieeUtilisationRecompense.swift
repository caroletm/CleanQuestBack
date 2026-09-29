//
//  AddExpirationNotifieeUtilisationRecompense.swift
//  CleanQuest_Back
//
//  Created by caroletm on 29/09/2026.
//

import Foundation
import Fluent
import FluentSQL

struct AddExpirationNotifieeUtilisationRecompense: AsyncMigration {

    func prepare(on db: any Database) async throws {
        try await db.schema("utilisation_recompense")
            .field("expirationNotifiee", .bool, .required, .sql(.default(false)))
            .update()

        // Les cartes déjà expirées avant cette migration ne doivent pas déclencher une rafale de push au démarrage.
        try await UtilisationRecompense.query(on: db)
            .filter(\.$deadline <= Date())
            .set(\.$expirationNotifiee, to: true)
            .update()
    }

    func revert(on db: any Database) async throws {
        try await db.schema("utilisation_recompense")
            .deleteField("expirationNotifiee")
            .update()
    }
}
