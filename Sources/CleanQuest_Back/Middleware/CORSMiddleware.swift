//
//  CORSMiddleware.swift
//  CleanQuest_Back
//
//  Created by caroletm on 08/03/2026.
//

import Gatekeeper
import Vapor
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS],
    allowedHeaders: [.accept, .authorization, .contentType, .origin],
    cacheExpiration: 800
)
