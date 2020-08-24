import Vapor
import Smtp

final class ContactFormController {
    
    func validateFormAndSendMail(req: Request) throws -> EventLoopFuture<String> {
        var params = try req.content.decode(Dictionary<String, String>.self)
        
        guard let toKey = params.removeValue(forKey: "to"),
            let fromValue = params.removeValue(forKey: "from"),
            let subject = params.removeValue(forKey: "subject"),
            var body = params.removeValue(forKey: "body") else {
                throw Abort(.badRequest, reason: "missing key 'to', 'from', 'subject' or 'body'")
        }
        
        guard let toValue = Environment.get(toKey) else {
            throw Abort(.badRequest, reason: "unknown value for key 'to'")
        }
        
        var validations = Validations()
        validations.add("from", as: String.self, is: .email)
        
        if let error = try validations.validate(request: req).error {
            throw Abort(.badRequest, reason: "\(error)")
        }
        
        let name = params.removeValue(forKey: "name")
        let additionalParams = params.map({ "\($0): \($1)" }).joined(separator: "\n")
        
        if !additionalParams.isEmpty {
            body += "\n\n–––––––\n\(additionalParams)\n"
        }
        
        let separator = " | "
        
        let to: EmailAddress
        if toValue.contains(separator) {
            let parts = toValue.components(separatedBy: separator)
            to = EmailAddress(address: parts[1], name: parts[0])
        } else {
            to = EmailAddress(address: toValue)
        }
        
        let from = EmailAddress(address: fromValue, name: name)
        let email = Email(from: from, to: [to], subject: subject, body: body)
        
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
