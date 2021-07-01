import Vapor

final class ProxyController {
    struct Params: Content {
        let url: String
        let headers: HTTPHeaders?
        let query: Dictionary<String, String>?
        let data: Dictionary<String, String>?
    }
    
    func send(req: Request) throws -> EventLoopFuture<ClientResponse> {
        let params = try req.content.decode(Params.self)
        let uri = URI(string: params.url)
        let method: (_ url: URI, _ headers: HTTPHeaders, _ beforeSend: (inout ClientRequest) throws -> () ) -> EventLoopFuture<ClientResponse>
        
        guard let host = uri.host,
              let allowedHosts = Environment.get("allowedHosts")?.components(separatedBy: " "),
              allowedHosts.contains(host) else {
            return req.eventLoop.future(error: Abort(.badRequest, reason: "unsupported host name"))
        }
        
        switch req.method {
        case .GET:
            method = req.client.get
        case .POST:
            method = req.client.post
        case .PUT:
            method = req.client.put
        case .DELETE:
            method = req.client.delete
        default:
            return req.eventLoop.future(error: Abort(.badRequest, reason: "unsupported http method"))
        }
        
        return method(uri, params.headers ?? [:]) { req in
            if let query = params.query {
                try req.query.encode(query)
            }
            
            if let data = params.data {
                try req.query.encode(data)
            }
        }
    }
}
