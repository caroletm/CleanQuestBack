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
}

private extension ByteBuffer {
    var string: String? { getString(at: readerIndex, length: readableBytes) }
}
