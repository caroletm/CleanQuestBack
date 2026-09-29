import NIOSSL
import Fluent
import FluentMySQLDriver
import Vapor
import FluentSQL
import JWT
import APNS
import APNSCore
import VaporAPNS

// configures your application
public func configure(_ app: Application) async throws {

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
    
    // Avant FileMiddleware : il doit englober la réponse du fichier pour pouvoir y ajouter l'en-tête.
    app.middleware.use(CacheIconesMiddleware())
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    let brevoAPIKey = Environment.get("BREVO_API_KEY") ?? ""
    app.storage[BrevoAPIKey.self] = brevoAPIKey
    
    //MIGRATIONSet
    app.migrations.add(CreateUser())
    app.migrations.add(CreateFoyer())
    app.migrations.add(CreateMembre())
    app.migrations.add(CreateRecompense())
    app.migrations.add(CreateUtilisationRecompense())
    app.migrations.add(CreateCategorieRecompense())
    app.migrations.add(CreateTache())
    app.migrations.add(CreateCategorieTache())
    
    app.migrations.add(CreateOccurenceTache())
    app.migrations.add(CreateIcone())
    app.migrations.add(SeedIcones())
    app.migrations.add(UpdateFKMembre())
    app.migrations.add(UpdateFKRecompense())
    app.migrations.add(UpdateFKUtilisationRecompense())
    app.migrations.add(UpdateFKTache())
    app.migrations.add(UpdateFKOcurrenceTache())
    app.migrations.add(UpdateDatePlanifieeOccurenceTache())
    app.migrations.add(UpdateFKCategorieTache())
    app.migrations.add(UpdateUser())
    app.migrations.add(CreateTacheTemplate())
    app.migrations.add(UpdateFKTacheTemplate())
    app.migrations.add(UpdateDatesRealiseeValideeOccurenceTache())
    app.migrations.add(RemoveImageEnCoursRecompense())
    app.migrations.add(AddDureeMinutesRecompense())
    app.migrations.add(AddUniqueOccurenceTache())
    app.migrations.add(UpdateUtilisationRecompense())
    app.migrations.add(UpdateDateCreationFoyer())
    app.migrations.add(CreateDeviceToken())
    app.migrations.add(AddExpirationNotifieeUtilisationRecompense())
    app.migrations.add(AddBadgeUser())
    app.migrations.add(AddResetPasswordUser())
    app.migrations.add(AddEstSupprimeMembre())

    try await app.autoMigrate()

    // Seeds
    try await seedCategoriesTache(on: app.db)
    try await seedTacheTemplates(on: app.db)
    try await seedCategoriesRecompense(on: app.db)
    try await seedRecompenses(on: app.db)

    // register commands
    app.asyncCommands.use(GenererOccurrencesCommand(), as: "generer-occurrences")

    // Push APNs : sans les variables d'env, le serveur démarre quand même mais n'envoie pas de push.
    if let keyPath = Environment.get("APNS_KEY_PATH"),
       let keyId = Environment.get("APNS_KEY_ID"),
       let teamId = Environment.get("APNS_TEAM_ID") {
        let apnsConfig = APNSClientConfiguration(
            authenticationMethod: .jwt(
                privateKey: try .loadFrom(string: String(contentsOfFile: keyPath, encoding: .utf8)),
                keyIdentifier: keyId,
                teamIdentifier: teamId
            ),
            environment: .development
        )
        app.apns.containers.use(
            apnsConfig,
            eventLoopGroupProvider: .shared(app.eventLoopGroup),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default
        )
    } else {
        print("⚠️ Variables APNS_* manquantes : push désactivés")
    }

    // register routes
    try routes(app)

    ExpirationService.demarrer(app: app)
    PurgeService.demarrer(app: app)
}
