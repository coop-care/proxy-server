import Vapor
import Smtp

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin, HTTPHeaders.Name("api-key")]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    let error = ErrorMiddleware.default(environment: app.environment)
    // Clear any existing middleware.
    app.middleware = .init()
    app.middleware.use(cors)
    app.middleware.use(error)
    
    if let smtpHost = Environment.get("smtpHost"),
        let smtpUsername = Environment.get("smtpUsername"),
        let smtpPassword = Environment.get("smtpPassword") {
            app.smtp.configuration.hostname = smtpHost
            app.smtp.configuration.username = smtpUsername
            app.smtp.configuration.password = smtpPassword
            app.smtp.configuration.secure = .ssl
            app.smtp.configuration.helloMethod = .ehlo
    }

    // register routes
    try routes(app)
}
