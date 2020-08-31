import Vapor

func routes(_ app: Application) throws {
    let contactFormController = ContactFormController()
    let newsletterController = SendinblueController()
    
    app.post("contact", use: contactFormController.validateFormAndSendMail)
    app.post("newsletter", "subscribe", use: newsletterController.subscribe)
}
