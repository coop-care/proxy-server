import Vapor
import Smtp

extension String {
    func encodingForSmtp() -> String {
        return "=?utf-8?B?\(Data(self.utf8).base64EncodedString())?="
    }
}

final class ContactFormController {
    
    func validateFormAndSendMail(req: Request) throws -> EventLoopFuture<String> {
        struct Params: Content {
            let to: String
            let from: String
            let subject: String
            let body: String
            let name: String?
            let files: [File]
            let additional: Dictionary<String, String>?
        }
        let params = try req.content.decode(Params.self)
        
        guard let toValue = Environment.get(params.to) else {
            throw Abort(.badRequest, reason: "unknown value for key 'to'")
        }
        
        var validations = Validations()
        validations.add("from", as: String.self, is: .email)
        
        if let error = try validations.validate(request: req).error {
            throw Abort(.badRequest, reason: "\(error)")
        }
        
        var body = params.body + "\n\n"
        let additionalParams = params.additional?.map({ "\($0): \($1)" }).joined(separator: "\n") ?? ""
        
        if !additionalParams.isEmpty {
            body += "–––––––\n\(additionalParams)\n\n\n"
        }
        
        let separator = " | "
        
        let to: EmailAddress
        if toValue.contains(separator) {
            let parts = toValue.components(separatedBy: separator)
            to = EmailAddress(address: parts[1], name: parts[0].encodingForSmtp())
        } else {
            to = EmailAddress(address: toValue)
        }
        
        let from = EmailAddress(address: params.from, name: params.name?.encodingForSmtp())
        let subject = params.subject.encodingForSmtp()
        var email = Email(from: from, to: [to], subject: subject, body: body)
        
        params.files
            .filter { $0.data.readableBytes > 0 }
            .forEach { file in
                let contentType = file.contentType?.serialize() ?? ""
                let data = Data(buffer: file.data)
                let attachment = Attachment(name: file.filename, contentType: contentType, data: data)
                email.addAttachment(attachment)
                return
            }
        
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
