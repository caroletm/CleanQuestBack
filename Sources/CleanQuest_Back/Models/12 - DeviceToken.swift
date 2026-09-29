//
//  12 - DeviceToken.swift
//  CleanQuest_Back
//
//  Created by caroletm on 28/09/2026.
//

import Vapor
import Fluent

final class DeviceToken: Model, Content, @unchecked Sendable {
    static let schema = "device_tokens"

    @ID(key: .id) var id: UUID?
    @Field(key: "token") var token: String
    @Parent(key: "user_id") var user: User

    init() {
        self.id = UUID()
    }

    init(id: UUID? = nil, token: String, userId: UUID) {
        self.id = id ?? UUID()
        self.token = token
        self.$user.id = userId
    }
}
