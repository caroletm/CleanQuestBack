//
//  UserDTO.swift
//  CleanQuest_Back
//
//  Created by caroletm on 13/04/2026.
//

import Vapor

struct UserCreateDTO : Content {
    var name : String
    var email : String
    var password: String
}

struct UserDTO : Content {
    var id: UUID?
    var name: String
    var email: String
}

struct UserUpdateDTO : Content {
    var name: String?
    var email: String?
    var password: String?
}
