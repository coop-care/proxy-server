import Vapor

func routes(_ app: Application) throws {
    let contactFormController = ContactFormController()
    let newsletterController = SendinblueController()
    let mailController = MailController()
    let proxyController = ProxyController()
    
    app.post("mail", use: mailController.sendTemplate)
    app.post("mail", "form", use: contactFormController.validateFormAndSendMail)
    app.post("newsletter", "subscribe", use: newsletterController.subscribe)
    
    app.get("proxy", use: proxyController.send)
    app.post("proxy", use: proxyController.send)
    app.put("proxy", use: proxyController.send)
    app.delete("proxy", use: proxyController.send)
}
