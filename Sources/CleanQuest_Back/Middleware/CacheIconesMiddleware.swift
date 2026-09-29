//
//  CacheIconesMiddleware.swift
//  CleanQuest_Back
//
//  Created by caroletm on 29/09/2026.
//

import Vapor

// Les icônes du dossier Public ne changent jamais : le téléphone peut les garder 7 jours sans redemander.
struct CacheIconesMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)

        let chemin = request.url.path
        if chemin.hasPrefix("/CleanQuest_task_icons/") || chemin.hasPrefix("/CleanQuest_reward_icons/"),
           response.status == .ok {
            response.headers.replaceOrAdd(name: .cacheControl, value: "public, max-age=604800")
        }
        return response
    }
}
