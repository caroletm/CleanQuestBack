import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    try app.register(collection: UserController())
    try app.register(collection: FoyerController())
    try app.register(collection: MembreController())
    try app.register(collection: TacheController())
    try app.register(collection: RecompenseController())
    
}
