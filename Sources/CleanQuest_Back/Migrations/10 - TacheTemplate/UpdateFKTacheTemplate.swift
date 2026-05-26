import Fluent

struct UpdateFKTacheTemplate: AsyncMigration {

    func prepare(on db: any Database) async throws {
        try await db.schema("taches_templates")
            .field("foyer_id", .uuid,
                   .references("foyers", "id", onDelete: .cascade))
            .update()
    }

    func revert(on db: any Database) async throws {
        try await db.schema("taches_templates")
            .deleteField("foyer_id")
            .update()
    }
}
