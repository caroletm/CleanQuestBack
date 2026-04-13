//
//  9 - LoginRequest.swift
//  CleanQuest_Back
//
//  Created by caroletm on 13/04/2026.
//

import Vapor

struct LoginRequest: Content {
    let email: String
    let password: String
}
