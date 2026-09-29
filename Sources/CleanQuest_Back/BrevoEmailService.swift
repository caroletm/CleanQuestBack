//
//  BrevoEmailService.swift
//  CleanQuest_Back
//
//  Created by caroletm on 17/04/2026.
//

import Vapor

struct BrevoAPIKey: StorageKey {
    typealias Value = String
}

struct BrevoEmailService {

    static func sendEmail(
        req: Request,
        to email: String,
        subject: String,
        html: String
    ) async throws {

        guard let apiKey = req.application.storage[BrevoAPIKey.self],
              apiKey.isEmpty == false else {
            throw Abort(.internalServerError, reason: "BREVO_API_KEY manquante")
        }

        // Corps JSON manuel (plus sûr que encode pour ton cas)
        let payload: [String: Any] = [
            "sender": [
                "name": "CleanQuest",
                "email": "caroletrem94@hotmail.com"
            ],
            "to": [
                ["email": email]
            ],
            "subject": subject,
            "htmlContent": html
        ]

        // Convertir en Data JSON
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var clientRequest = ClientRequest()
        clientRequest.method = .POST
        clientRequest.url = URI(string: "https://api.brevo.com/v3/smtp/email")
        clientRequest.headers = HTTPHeaders([
            ("accept", "application/json"),
            ("api-key", apiKey),
            ("content-type", "application/json")
        ])
        clientRequest.body = .init(data: jsonData)

        let response = try await req.client.send(clientRequest)

        // Succès = n'importe quel 2xx
        guard (200..<300).contains(response.status.code) else {
            let errorBody = response.body?.string ?? "<aucun message>"
            throw Abort(.badRequest, reason: "Brevo error → \(errorBody)")
        }
    }

    static func sendInvitation(
        req: Request,
        nom: String,
        email: String,
        foyer: Foyer
    ) async throws {

        let html = """
        <h2>🧹 Bienvenue dans la communauté CleanQuest\n</h2>
        <p>Bonjour <strong>\(nom)</strong>,</p>
        <p>Tu as été invité.e à rejoindre le foyer :</p>
        <p><strong>\(foyer.nom) </strong></p>
        <p>Voici le code pour rejoindre ton foyer :</p>
        <h3 style="color:#B9BBF6;">\(foyer.codeFoyer)</h3>
        <p>🧽 Installe l'application avec cette adresse mail et entre ce code pour participer.</p>

        """

        try await sendEmail(
            req: req,
            to: email,
            subject: "Rejoins ton foyer CleanQuest",
            html: html)
    }

    static func sendResetCode(
        req: Request,
        nom: String,
        email: String,
        code: String
    ) async throws {

        let html = """
        <h2>🔑 Réinitialisation de ton mot de passe</h2>
        <p>Bonjour <strong>\(nom)</strong>,</p>
        <p>Voici ton code pour choisir un nouveau mot de passe dans l'application CleanQuest :</p>
        <h1 style="color:#B9BBF6; letter-spacing:6px;">\(code)</h1>
        <p>Ce code est valable 15 minutes.</p>
        <p>Si tu n'as rien demandé, ignore simplement cet email : ton mot de passe ne change pas.</p>
        """

        try await sendEmail(
            req: req,
            to: email,
            subject: "Ton code CleanQuest",
            html: html)
    }
}

private extension ByteBuffer {
    var string: String? { getString(at: readerIndex, length: readableBytes) }
}
