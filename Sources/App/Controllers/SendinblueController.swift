import Vapor

private struct SubscriptionRequest: Content {
    let email: String
    let includeListIds: [Int]
    let templateId: Int
    let redirectionUrl: String
}

final class SendinblueController {
    
    func subscribe(req: Request) throws -> EventLoopFuture<String> {
        var params = try req.content.decode(Dictionary<String, String>.self)
        
        guard let parameterKey = params.removeValue(forKey: "aid"),
            let recipientEmail = params.removeValue(forKey: "email"),
            let redirectionUrl = params.removeValue(forKey: "redirect") else {
                throw Abort(.badRequest, reason: "missing key 'aid', 'email' or 'redirect'")
        }
        
        guard let parameterList = Environment.get(parameterKey) else {
                throw Abort(.badRequest, reason: "unknown value for key 'aid'")
        }
        
        let parameters = parameterList.components(separatedBy: " | ")
        
        guard let credentials = Environment.get("sendinblueCredentials"),
            parameters.count == 2,
            let listId = Int(parameters[0]),
            let templateId = Int(parameters[1]) else {
                throw Abort(.badRequest, reason: "error in server-side configuration")
        }
        
        var validations = Validations()
        validations.add("email", as: String.self, is: .email)
        
        if let error = try validations.validate(request: req).error {
            throw Abort(.unprocessableEntity, reason: "\(error)")
        }
        
        let headers = HTTPHeaders([
            ("api-key", credentials),
            ("Accept", "application/json"),
            ("Content-Type", "application/json")
        ])
        let data = SubscriptionRequest(email: recipientEmail, includeListIds: [listId], templateId: templateId, redirectionUrl: redirectionUrl)
        
        return req.client.post("https://api.sendinblue.com/v3/contacts/doubleOptinConfirmation", headers: headers) { req in
            try req.content.encode(data)
        }.flatMapThrowing { res in
            if [HTTPStatus.ok, .created, .accepted, .noContent].contains(res.status) {
                return "{\"success\": true}"
            } else {
                throw Abort(.badRequest, reason: "error in provider response")
            }
        }
    }
    
}
