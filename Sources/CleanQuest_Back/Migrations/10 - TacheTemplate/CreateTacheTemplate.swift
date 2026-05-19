import Fluent

struct CreateTacheTemplate: AsyncMigration {
    func prepare(on db: any Database) async throws {
        try await db.schema("taches_templates")
            .id()
            .field("nom", .string, .required)
            .field("categorie_id", .uuid, .required,
                   .references("categorie_tache", "id", onDelete: .cascade))
            .create()
    }

    func revert(on db: any Database) async throws {
        try await db.schema("taches_templates").delete()
    }
}
