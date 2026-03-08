//
//  JWTMiddleware.swift
//  CleanQuest_Back
//
//  Created by caroletm on 08/03/2026.
//
//
import Vapor
import JWT

final class JWTMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        
        guard let token = request.headers["Authorization"].first?.split(separator: " ").last else {
            return request.eventLoop.future(error: Abort(.unauthorized, reason: "Token manquant"))
        }
        
        guard let secret = Environment.get("JWT_SECRET") else {
            fatalError("JWT_SECRET manquant")
        }

        let signer = JWTSigner.hs256(key: secret)
        let payload : UserPayload
        
        do {
            payload = try signer.verify(String(token), as : UserPayload.self)
        }catch{
            return request.eventLoop.future(error: Abort(.unauthorized, reason: "Token invalide"))
        }
        request.auth.login(payload)
        
        return next.respond(to: request)
    }
}
