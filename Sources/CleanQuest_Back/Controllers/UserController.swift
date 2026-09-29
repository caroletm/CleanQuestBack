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
        users.post("password", "forgot", use: forgotPassword)
        users.post("password", "reset", use: resetPassword)
        
        let protected = users.grouped(JWTMiddleware())
        protected.get("profile", use: profile)
        protected.post("device-token", use: saveDeviceToken)
        protected.delete("device-token", ":deviceToken", use: deleteDeviceToken)
        protected.post("test-push", use: testPush)
        protected.post("badge", "reset", use: resetBadge)
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
        onboarding: true
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

// Un user ne peut lire, modifier ou supprimer que son propre compte.
func exigerSonPropreCompte(_ req: Request) throws -> UUID {
    let payload = try req.auth.require(UserPayload.self)
    guard let id = req.parameters.get("id", as: UUID.self) else {
        throw Abort(.badRequest, reason: "ID invalide")
    }
    guard id == payload.id else {
        throw Abort(.forbidden, reason: "Vous ne pouvez agir que sur votre propre compte")
    }
    return id
}

//GET/users/:id
@Sendable
func getUserById(req: Request) async throws -> UserDTO {
    let id = try exigerSonPropreCompte(req)
    guard let user = try await User.find(id, on: req.db) else {
        throw Abort(.notFound)
    }
    return UserDTO(id: id, name: user.nom, email: user.email, firstConnection: user.onboarding)
}

//MARK: - DELETE USER

@Sendable
func deleteUserById(_ req: Request) async throws -> Response {
    let id = try exigerSonPropreCompte(req)
    guard let user = try await User.find(id, on: req.db) else {
        throw Abort(.notFound)
    }

    // Le membre de la personne et ceux qu'elle gère deviennent des « anciens membres » :
    // leurs tâches et récompenses restent dans l'historique du foyer.
    // Les liens vers le compte sont coupés AVANT la suppression, sinon la cascade
    // sur gestionnaire_id effacerait les membres gérés et tout leur historique.
    let sesMembres = try await Membre.query(on: req.db)
        .group(.or) { group in
            group.filter(\.$user.$id == id)
            group.filter(\.$gestionnaire.$id == id)
        }
        .all()

    try await req.db.transaction { db in
        for membre in sesMembres {
            membre.nom = "Ancien membre"
            membre.email = ""
            membre.estSupprime = true
            membre.$user.id = nil
            membre.$gestionnaire.id = nil
            try await membre.save(on: db)
        }
        try await user.delete(on: db)
    }
    return Response(status: .ok)
}

//MARK: - PATCH USER

@Sendable
func updateUserById(req: Request) async throws -> UserDTO {
    
    let id = try exigerSonPropreCompte(req)
    
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
    if let firstConnection = dto.firstConnection { user.onboarding = firstConnection}

    try await user.save(on: req.db)
 
    guard let userId = user.id else {
        throw Abort(.internalServerError, reason: "ID de l'utilisateur manquant")
    }
    return UserDTO(id: userId, name: user.nom, email: user.email, firstConnection: user.onboarding)
}

//MARK: - NOTIFICATIONS PUSH

//POST/users/device-token
@Sendable
func saveDeviceToken(req: Request) async throws -> DeviceTokenDTO {
    let payload = try req.auth.require(UserPayload.self)
    let dto = try req.content.decode(DeviceTokenDTO.self)

    // Même iPhone, autre compte connecté : on rattache le token au nouveau user au lieu d'en créer un 2e.
    if let existant = try await DeviceToken.query(on: req.db)
        .filter(\.$token == dto.token)
        .first() {
        existant.$user.id = payload.id
        try await existant.save(on: req.db)
    } else {
        try await DeviceToken(token: dto.token, userId: payload.id).save(on: req.db)
    }

    return dto
}

//POST/users/test-push
@Sendable
func testPush(req: Request) async throws -> HTTPStatus {
    let payload = try req.auth.require(UserPayload.self)
    await PushService.envoyer(a: payload.id, titre: "CleanQuest", message: "Premier push depuis Vapor 🎉", on: req)
    return .ok
}

//POST/users/badge/reset
@Sendable
func resetBadge(req: Request) async throws -> BadgeDTO {
    let payload = try req.auth.require(UserPayload.self)
    guard let user = try await User.find(payload.id, on: req.db) else {
        throw Abort(.notFound)
    }
    user.badge = 0
    try await user.save(on: req.db)
    return BadgeDTO(badge: 0)
}

//DELETE/users/device-token/:deviceToken
@Sendable
func deleteDeviceToken(req: Request) async throws -> HTTPStatus {
    let payload = try req.auth.require(UserPayload.self)
    guard let deviceToken = req.parameters.get("deviceToken") else {
        throw Abort(.badRequest, reason: "deviceToken manquant")
    }

    try await DeviceToken.query(on: req.db)
        .filter(\.$token == deviceToken)
        .filter(\.$user.$id == payload.id)
        .delete()

    return .noContent
}

//MARK: - MOT DE PASSE OUBLIÉ

//POST/users/password/forgot
@Sendable
func forgotPassword(req: Request) async throws -> MessageDTO {
    let dto = try req.content.decode(ForgotPasswordDTO.self)
    let email = dto.email.trimmingCharacters(in: .whitespaces)

    if let user = try await User.query(on: req.db)
        .filter(\.$email == email)
        .first() {
        let code = String(format: "%06d", Int.random(in: 0...999_999))
        user.resetCode = try Bcrypt.hash(code)
        user.resetExpiration = Date().addingTimeInterval(15 * 60)
        user.resetEssais = 0
        try await user.save(on: req.db)

        try await BrevoEmailService.sendResetCode(req: req, nom: user.nom, email: user.email, code: code)
    }

    // Même réponse que le compte existe ou non : sinon on révèle quels emails sont inscrits.
    return MessageDTO(message: "Si un compte existe avec cet email, un code vient d'être envoyé.")
}

//POST/users/password/reset
@Sendable
func resetPassword(req: Request) async throws -> MessageDTO {
    let dto = try req.content.decode(ResetPasswordDTO.self)
    let email = dto.email.trimmingCharacters(in: .whitespaces)

    guard dto.nouveauMotDePasse.count >= 8 else {
        throw Abort(.badRequest, reason: "Le mot de passe doit contenir au moins 8 caractères")
    }

    guard let user = try await User.query(on: req.db)
            .filter(\.$email == email)
            .first(),
          let codeHache = user.resetCode,
          let expiration = user.resetExpiration,
          expiration > Date(),
          user.resetEssais < 5 else {
        throw Abort(.badRequest, reason: "Code invalide ou expiré. Redemande un nouveau code.")
    }

    guard try Bcrypt.verify(dto.code.trimmingCharacters(in: .whitespaces), created: codeHache) else {
        user.resetEssais += 1
        try await user.save(on: req.db)
        throw Abort(.badRequest, reason: "Code incorrect")
    }

    user.motDePasse = try Bcrypt.hash(dto.nouveauMotDePasse)
    user.resetCode = nil
    user.resetExpiration = nil
    user.resetEssais = 0
    try await user.save(on: req.db)

    return MessageDTO(message: "Mot de passe modifié")
}
