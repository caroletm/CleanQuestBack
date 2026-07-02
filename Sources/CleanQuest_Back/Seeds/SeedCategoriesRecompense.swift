import Fluent

func seedCategoriesRecompense(on db: any Database) async throws {
    let categoriesParDefaut = [
        "privilege",
        "action"
    ]

    for nom in categoriesParDefaut {
        let existe = try await CategorieRecompense.query(on: db)
            .filter(\.$nom == nom)
            .first()
        if existe == nil {
            try await CategorieRecompense(nom: nom).save(on: db)
        }
    }
}
