import Vapor

func routes(_ app: Application) throws {
    let contactFormController = ContactFormController()
    let newsletterController = SendinblueController()
    let mailController = MailController()
    let proxyController = ProxyController()
    
    app.post("mail", use: mailController.sendTemplate)
    app.post("mail", "form", use: contactFormController.validateFormAndSendMail)
    app.post("newsletter", "subscribe", use: newsletterController.subscribe)
    
    app.post("proxy", use: proxyController.send)
}
