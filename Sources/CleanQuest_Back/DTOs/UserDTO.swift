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
    var firstConnection : Bool
}

struct UserUpdateDTO : Content {
    var name: String?
    var email: String?
    var password: String?
    var firstConnection: Bool?
}

struct DeviceTokenDTO : Content {
    var token : String
}

struct BadgeDTO : Content {
    var badge : Int
}

struct ForgotPasswordDTO : Content {
    var email : String
}

struct ResetPasswordDTO : Content {
    var email : String
    var code : String
    var nouveauMotDePasse : String
}

struct MessageDTO : Content {
    var message : String
}
