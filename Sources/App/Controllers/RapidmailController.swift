import Vapor

final class RapidmailController {
    
    func subscribe(req: Request) throws -> EventLoopFuture<String> {
        var params = try req.content.decode(Dictionary<String, String>.self)
        
        guard let recipientListIdKey = params.removeValue(forKey: "aid"),
            let recipientEmail = params.removeValue(forKey: "email") else {
                throw Abort(.badRequest, reason: "missing key 'aid' or 'email'")
        }
        
        guard let recipientListId = Environment.get(recipientListIdKey) else {
            throw Abort(.badRequest, reason: "unknown value for key 'aid'")
        }
        
        guard let rapidmailCredentials = Environment.get("rapidmailCredentials") else {
            throw Abort(.badRequest, reason: "error in server-side configuration")
        }
        
        var validations = Validations()
        validations.add("email", as: String.self, is: .email)
        
        if let error = try validations.validate(request: req).error {
            throw Abort(.unprocessableEntity, reason: "\(error)")
        }
        
        let headers = [
            ("Authorization", "Basic " + Data(rapidmailCredentials.utf8).base64EncodedString()),
            ("Accept", "*/*"),
            ("Content-Type", "application/json")
        ]
        
        return req.client.post("https://apiv3.emailsys.net/v1/recipients", headers: HTTPHeaders(headers)) { req in
            try req.query.encode(["send_activationmail": "yes"]) // "test_mode": "yes"
            try req.content.encode(["email": recipientEmail, "recipientlist_id": recipientListId])
        }.flatMapThrowing { res in
            if [HTTPStatus.ok, .created, .conflict].contains(res.status) {
                return "{\"success\": true}"
            } else if res.status == .unprocessableEntity {
                throw Abort(.unprocessableEntity, reason: "invalid email address")
            } else {
                throw Abort(.badRequest, reason: "error in provider response")
            }
        }
    }
    
}
