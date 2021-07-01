import Vapor
import Smtp

final class MailController {
    
    func sendTemplate(req: Request) throws -> EventLoopFuture<String> {
        var params = try req.content.decode(Dictionary<String, String>.self)
        
        guard let to = params.removeValue(forKey: "to"),
            let fromKey = params.removeValue(forKey: "from"),
            let templateKey = params.removeValue(forKey: "template"),
            let locale = params.removeValue(forKey: "locale") else {
                throw Abort(.badRequest, reason: "missing key 'to', 'from', 'template' or 'locale'")
        }
        
        var validations = Validations()
        validations.add("to", as: String.self, is: .email)
        
        if let error = try validations.validate(request: req).error {
            throw Abort(.badRequest, reason: "\(error)")
        }
        
        guard let from = Environment.get(fromKey) else {
            throw Abort(.badRequest, reason: "unknown value for key 'from'")
        }
        
        guard let templateString = Environment.get(templateKey),
            let data = templateString.data(using: .utf8) else {
                throw Abort(.badRequest, reason: "unknown value for key 'template'")
        }
        
        let template = try JSONDecoder().decode([String: [String: String]].self, from: data)
        
        guard let localizedTemplate = template[locale],
            var subject = localizedTemplate["subject"],
            var body = localizedTemplate["body"] else {
                throw Abort(.badRequest, reason: "unknown value for key 'locale'")
        }
        
        params.forEach({ key, value in
            subject = subject.replacingOccurrences(of: "{\(key)}", with: value)
            body = body.replacingOccurrences(of: "{\(key)}", with: value)
        })
        
        let separator = " | "
        let fromAddress: EmailAddress
        if from.contains(separator) {
            let parts = from.components(separatedBy: separator)
            fromAddress = EmailAddress(address: parts[1], name: parts[0])
        } else {
            fromAddress = EmailAddress(address: from)
        }
        
        let toAddress = EmailAddress(address: to)
        let email = Email(from: fromAddress, to: [toAddress], subject: subject, body: body)
        
        return req.smtp.send(email).hop(to: req.eventLoop).flatMap { result -> EventLoopFuture<String> in
            switch result {
            case .success:
                return req.eventLoop.future("{\"success\": true}\n")
            case .failure(let error):
                print(error)
                return req.eventLoop.future(error: Abort(.badRequest, reason: "error while sending"))
            }
        }
    }
    
}
