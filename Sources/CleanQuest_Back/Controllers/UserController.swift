//
//  UserController.swift
//  CleanQuest_Back
//
//  Created by caroletm on 13/04/2026.
//

import Vapor
import Fluent
import JWT

struct UserController : RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.post(use: createUser)
        users.post("login", use: login)
        
        let protected = users.grouped(JWTMiddleware())
        protected.get("profile", use: profile)
        protected.get(use: getAllUsers)
        protected.get(":id", use: getUserById)
        protected.patch(":id", use: updateUserById)
        protected.delete(":id", use: deleteUserById)
    }
}

//MARK: - AUTHENTIFICATION

//POST/users
@Sendable
func createUser(_ req: Request) async throws -> UserDTO {
    
    let dto = try req.content.decode(UserCreateDTO.self)
    
    if try await User.query(on: req.db)
        .filter(\.$email == dto.email)
        .first() != nil {
        throw Abort(.badRequest, reason: "Email déjà existant")
    }
    
    if dto.password.count < 8 {
        throw Abort(.badRequest, reason: "Le mot de passe doit contenir au moins 8 caractères")
    }
    
    let hashedPassword = try Bcrypt.hash(dto.password)
    
    let user = User(
        nom: dto.name,
        email: dto.email,
        motDePasse: hashedPassword,
    )

    try await user.save(on: req.db)
    
    guard let id = user.id else {
        throw Abort(.internalServerError, reason: "ID de l'utilisateur manquant")
    }
    return UserDTO(
        id: id,
        name: user.nom,
        email: user.email,
        firstConnection: true)
}

//POST/users/login
struct LoginResponse : Content {
    let token: String
}

@Sendable
func login(req: Request) async throws -> LoginResponse {
    let userData = try req.content.decode(LoginRequest.self)
    
    guard let user = try await User.query(on: req.db)
        .filter(\.$email == userData.email)
        .first() else {
        throw Abort(.unauthorized, reason: "Identifiants invalides")
    }
    
    guard try Bcrypt.verify(userData.password, created: user.motDePasse) else {
        throw Abort(.unauthorized, reason: "Identifiants invalides")
    }
    
    guard let id = user.id else {
        throw Abort(.internalServerError, reason: "ID de l'utilisateur manquant")
    }
    let payload = UserPayload(id: id)
    
    guard let secret = Environment.get("JWT_SECRET") else {
        fatalError("JWT_SECRET manquant")
    }
    
    let signer = JWTSigner.hs256(key: secret)
    let token =  try signer.sign(payload)
    
    return LoginResponse(token: token)
}

//GET/users/profile
@Sendable
func profile(req: Request) async throws -> UserDTO {
    let payload = try req.auth.require(UserPayload.self)
    
    guard let user = try await User.find(payload.id, on: req.db) else {
        throw Abort(.notFound)
    }
    
    guard let id = user.id else {
        throw Abort(.internalServerError, reason: "ID de l'utilisateur manquant")
    }
    
    let memberCount = try await Membre.query(on: req.db)
        .filter(\.$user.$id == id)
        .count()
                    
    return UserDTO(
        id: id,
        name: user.nom,
        email: user.email,
        firstConnection: memberCount == 0)
}

//MARK: - GET USER

//GET/users
@Sendable
func getAllUsers(req: Request) async throws -> [UserDTO] {
    let users: [User] = try await User.query(on: req.db).all()
    
    return users.map { user in
        UserDTO(
            id: user.id,
            name: user.nom,
            email: user.email,
            firstConnection: true)
    }
}

//GET/users/:id
@Sendable
func getUserById(req: Request) async throws -> UserDTO {
    guard let user = try await User.find(req.parameters.require("id"), on: req.db) else {
        throw Abort(.notFound)
    }
    guard let id = user.id else {
        throw Abort(.internalServerError, reason: "ID de l'utilisateur manquant")
    }
    return UserDTO(id: id, name: user.nom, email: user.email, firstConnection: true)
}

//MARK: - DELETE USER

@Sendable
func deleteUserById(_ req: Request) async throws -> Response {
    guard let user = try await User.find(req.parameters.require("id"), on: req.db) else {
        throw Abort(.notFound)
    }
    try await user.delete(on: req.db)
    return Response(status: .ok)
}

//MARK: - PATCH USER

@Sendable
func updateUserById(req: Request) async throws -> UserDTO {
    
    guard let id = req.parameters.get("id", as: UUID.self) else {
        throw Abort(.badRequest, reason: "ID invalide")
    }
    
    guard let user = try await User.find(id, on: req.db) else {
        throw Abort(.notFound, reason: "Utilisateur introuvable")
    }
 
    let dto = try req.content.decode(UserUpdateDTO.self)
                
    if let name = dto.name { user.nom = name }
    if let email = dto.email { user.email = email }
    if let password = dto.password {
        if password.count < 8 {
            throw Abort(.badRequest, reason: "Le mot de passe doit contenir au moins 8 caractères")
        }
        user.motDePasse = try Bcrypt.hash(password)
    }

    try await user.save(on: req.db)
 
    guard let userId = user.id else {
        throw Abort(.internalServerError, reason: "ID de l'utilisateur manquant")
    }
    return UserDTO(id: userId, name: user.nom, email: user.email, firstConnection: true)
}
