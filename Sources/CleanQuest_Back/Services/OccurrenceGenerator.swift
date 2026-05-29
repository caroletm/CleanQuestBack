//
//  OccurrenceGenerator.swift
//  CleanQuest_Back
//
//  Génère les occurrences d'une tâche selon sa fréquence, sur une fenêtre
//  glissante en avant. Réutilisé par la commande planifiée et par les routes
//  de création/modification de tâche.
//

import Vapor
import Fluent

enum OccurrenceGenerator {

    /// Taille de la fenêtre de génération en avant (jours fixes).
    static let fenetreJours = 30

    /// Calendrier utilisé pour tous les calculs de dates.
    static func calendrier() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris") ?? .current
        return calendar
    }

    /// Date suivante de la série, à partir de `date`.
    /// `index` = position dans la série depuis l'ancre (0 = ancre), nécessaire
    /// pour les patterns alternés (biHebdomadaire +3/+4).
    /// Renvoie `nil` pour une fréquence `unique` (pas de suite).
    static func dateSuivante(
        apres date: Date,
        frequence: FrequenceTache,
        index: Int,
        calendar: Calendar
    ) -> Date? {
        switch frequence {
        case .unique:
            return nil
        case .quotidienne:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .biQuotidienne:
            return calendar.date(byAdding: .hour, value: 12, to: date)
        case .hebdomadaire:
            return calendar.date(byAdding: .day, value: 7, to: date)
        case .biHebdomadaire:
            // 2×/semaine sur 2 jours fixes : +3 puis +4 en alternance
            let pas = (index % 2 == 0) ? 3 : 4
            return calendar.date(byAdding: .day, value: pas, to: date)
        case .mensuelle:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .biMensuelle:
            // tous les 15 jours
            return calendar.date(byAdding: .day, value: 15, to: date)
        }
    }

    /// Crée en base les occurrences manquantes de la tâche jusqu'à `fin`.
    ///
    /// - `ancre` : origine de la série (échéance d'origine de la tâche). La grille
    ///   est calculée depuis l'ancre pour garder la phase correcte ; seules les
    ///   dates **postérieures à la dernière occurrence existante** sont insérées,
    ///   ce qui rend l'opération idempotente (pas de doublon si on relance).
    /// - `apartir` : plancher optionnel — n'insère que les dates strictement
    ///   postérieures à cette date (utilisé pour ne régénérer que le futur).
    /// - Renvoie le nombre d'occurrences créées.
    @discardableResult
    static func genererOccurrences(
        pour tache: Tache,
        ancre: Date,
        jusqua fin: Date,
        apartir plancher: Date? = nil,
        on db: any Database
    ) async throws -> Int {
        guard tache.frequence != .unique else { return 0 }
        let tacheId = try tache.requireID()

        let derniereExistante = try await OccurenceTache.query(on: db)
            .filter(\.$tache.$id == tacheId)
            .sort(\.$datePlanifiee, .descending)
            .first()?
            .datePlanifiee

        let calendar = calendrier()
        var creees = 0
        var date = ancre
        var index = 0
        let maxIterations = 2000 // garde-fou anti-boucle infinie

        while date <= fin && index < maxIterations {
            var aGenerer = derniereExistante.map { date > $0 } ?? true
            if let plancher, date <= plancher { aGenerer = false }
            if aGenerer {
                let occurence = OccurenceTache(
                    datePlanifiee: date,
                    statut: .aFaire,
                    tacheId: tacheId
                )
                try await occurence.save(on: db)
                creees += 1
            }
            guard let suivante = dateSuivante(
                apres: date,
                frequence: tache.frequence,
                index: index,
                calendar: calendar
            ) else {
                break
            }
            date = suivante
            index += 1
        }
        return creees
    }
}
