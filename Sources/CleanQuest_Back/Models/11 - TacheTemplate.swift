import Vapor
import Fluent

final class TacheTemplate: Model, Content, @unchecked Sendable {
    static let schema = "taches_templates"

    @ID(key: .id) var id: UUID?
    @Field(key: "nom") var nom: String
    @Parent(key: "categorie_id") var categorie: CategorieTache
    @OptionalParent(key: "foyer_id") var foyer: Foyer?

    init() { self.id = UUID() }
    init(id: UUID? = nil, nom: String, categorieId: UUID, foyerId: UUID? = nil) {
        self.id = id ?? UUID()
        self.nom = nom
        self.$categorie.id = categorieId
        self.$foyer.id = foyerId
    }
}
