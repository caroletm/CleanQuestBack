import Fluent

func seedTacheTemplates(on db: any Database) async throws {
    let tachesParCategorie: [(categorie: String, taches: [String])] = [
        ("Cuisine", [
            "Faire la vaisselle",
            "Nettoyer le plan de travail",
            "Nettoyer les plaques de cuisson",
            "Vider la poubelle",
            "Sortir les poubelles",
            "Nettoyer le frigo"
        ]),
        ("Salle de Bain / WC", [
            "Nettoyer le lavabo",
            "Nettoyer la douche",
            "Nettoyer les WC",
            "Nettoyer le miroir",
            "Vider la poubelle",
            "Réapprovisionner papier toilette / savon"
        ]),
        ("Chambre", [
            "Faire le lit",
            "Changer les draps",
            "Ranger la chambre",
            "Dépoussiérer les meubles",
            "Aérer la pièce",
            "Ranger les vêtements"
        ]),
        ("Salon / Salle à manger", [
            "Ranger le salon",
            "Dépoussiérer les meubles",
            "Nettoyer la table basse",
            "Aspirer le sol",
            "Laver le sol",
            "Nettoyer les vitres"
        ]),
        ("Linge", [
            "Lancer une machine",
            "Étendre le linge",
            "Plier le linge",
            "Ranger le linge",
            "Repasser",
            "Nettoyer le lave-linge"
        ]),
        ("Sols", [
            "Passer le balai",
            "Passer l'aspirateur",
            "Laver les sols",
            "Nettoyer les plinthes",
            "Nettoyer les tapis",
            "Nettoyer les poignées de porte"
        ]),
        ("Surfaces", [
            "Dépoussiérer les surfaces hautes",
            "Nettoyer les interrupteurs / poignées",
            "Dépoussiérer les meubles",
            "Nettoyer les étagères",
            "Ranger les placards"
        ]),
        ("Vitres", [
            "Nettoyer les vitres intérieures",
            "Nettoyer les vitres extérieures",
            "Nettoyer les rebords de fenêtres",
            "Nettoyer le miroir",
            "Nettoyer les baies vitrées"
        ]),
        ("Extérieur", [
            "Nettoyer le balcon / terrasse",
            "Balayer l'entrée",
            "Sortir les poubelles",
            "Tondre la pelouse",
            "Désherber"
        ]),
        ("Entretien", [
            "Détartrer la cafetière",
            "Nettoyer la hotte",
            "Nettoyer les filtres",
            "Dégivrer le congélateur",
            "Nettoyage de printemps",
            "Trier les papiers"
        ]),
        ("Enfants", [
            "Ranger les jouets",
            "Nettoyer la chaise haute",
            "Laver les biberons",
            "Nettoyer la chambre d'enfant",
            "Trier les vêtements"
        ]),
        ("Animaux", [
            "Nettoyer la litière",
            "Sortir le chien",
            "Nettoyer les gamelles",
            "Aspirer les poils",
            "Nourrir les animaux"
        ])
    ]

    for entry in tachesParCategorie {
        guard let categorie = try await CategorieTache.query(on: db)
            .filter(\.$nom == entry.categorie)
            .filter(\.$foyer.$id == nil)
            .first()
        else { continue }

        for nomTache in entry.taches {
            let existe = try await TacheTemplate.query(on: db)
                .filter(\.$nom == nomTache)
                .filter(\.$categorie.$id == categorie.id!)
                .first()
            if existe == nil {
                try await TacheTemplate(nom: nomTache, categorieId: categorie.id!).save(on: db)
            }
        }
    }
}
