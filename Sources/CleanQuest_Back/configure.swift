import NIOSSL
import Fluent
import FluentMySQLDriver
import Vapor
import FluentSQL
import JWT

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(DatabaseConfigurationFactory.mysql(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 3306,
        username: Environment.get("DATABASE_USERNAME") ?? "root",
        password: Environment.get("DATABASE_PASSWORD") ?? "",
        database: Environment.get("DATABASE_NAME") ?? "CleanQuest"
    ), as: .mysql)

//    app.migrations.add(CreateTodo())
    
    //Test rapide de connexion
    if let sql = app.db(.mysql) as? (any SQLDatabase) {
        sql.raw("SELECT 1").run().whenComplete { response in
            print(response)
        }
    } else {
        print("⚠️ Le driver SQL n'est pas disponible (cast vers SQLDatabase impossible)")
    }
    
    enum JWTConfig {
        static func signer() -> JWTSigner {
            guard let secret = Environment.get("JWT_SECRET") else {
                fatalError("JWT_SECRET is not set")
            }
            return JWTSigner.hs256(key: secret)
        }
    }
    
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin],
        cacheExpiration: 800
    )

    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
    
    let brevoAPIKey = Environment.get("BREVO_API_KEY") ?? ""
    app.storage[BrevoAPIKey.self] = brevoAPIKey
    
    //MIGRATIONS
    app.migrations.add(CreateUser())
    app.migrations.add(CreateFoyer())
    app.migrations.add(CreateMembre())
    app.migrations.add(CreateRecompense())
    app.migrations.add(CreateUtilisationRecompense())
    app.migrations.add(CreateCategorieRecompense())
    app.migrations.add(CreateTache())
    app.migrations.add(CreateCategorieTache())
    app.migrations.add(CreateOccurenceTache())
    app.migrations.add(UpdateFKMembre())
    app.migrations.add(UpdateFKRecompense())
    app.migrations.add(UpdateFKUtilisationRecompense())
    app.migrations.add(UpdateFKTache())
    app.migrations.add(UpdateFKOcurrenceTache())
    app.migrations.add(UpdateFKCategorieTache())
    
    try await app.autoMigrate()

    // register routes
    try routes(app)
}
