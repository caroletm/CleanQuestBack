//
//  UserPayload.swift
//  CleanQuest_Back
//
//  Created by caroletm on 08/03/2026.
//

import Foundation
import Vapor
import JWT

struct UserPayload: JWTPayload, Authenticatable {
    var id : UUID
    var expiration: Date
    
    func verify(using signer: JWTSigner) throws {
        if self.expiration < Date() {
            throw JWTError.invalidJWK
        }
    }
    init(id:UUID) {
        self.id = id
        self.expiration = Date().addingTimeInterval(3600 * 24)
    }
}
