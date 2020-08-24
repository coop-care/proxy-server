import Vapor

func routes(_ app: Application) throws {
    let contactFormController = ContactFormController()
    let rapidmailController = RapidmailController()
    
    app.post("contact", use: contactFormController.validateFormAndSendMail)
    app.post("newsletter", "subscribe", use: rapidmailController.subscribe)
}
