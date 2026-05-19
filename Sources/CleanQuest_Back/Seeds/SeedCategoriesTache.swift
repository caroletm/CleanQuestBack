import Fluent

func seedCategoriesTache(on db: any Database) async throws {
    let categoriesParDefaut = [
        "Salle de Bain / WC",
        "Cuisine",
        "Chambre",
        "Salon / Salle à manger",
        "Linge",
        "Sols",
        "Surfaces",
        "Vitres",
        "Extérieur",
        "Entretien",
        "Enfants",
        "Animaux",
        "Autres"
    ]

    for nom in categoriesParDefaut {
        let existe = try await CategorieTache.query(on: db)
            .filter(\.$nom == nom)
            .filter(\.$foyer.$id == nil)
            .first()
        if existe == nil {
            try await CategorieTache(nom: nom).save(on: db)
        }
    }
}
