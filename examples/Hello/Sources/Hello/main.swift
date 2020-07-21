import Vapor
import VaporAWSLambdaRuntime
#if DEBUG
    import AWSLambdaRuntimeCore
#endif

let app = Application()

struct Name: Codable {
    let name: String
}

struct Hello: Content {
    let hello: String
}

app.get("hello") { (_) -> Hello in
    Hello(hello: "world")
}

app.post("hello") { req -> Hello in
    let name = try req.content.decode(Name.self)
    return Hello(hello: name.name)
}

// #if DEBUG
// try Lambda.withLocalServer {
app.servers.use(.lambda)
try app.run()
// }
// #else
// app.servers.use(.lambda)
// try app.run()
// #endif
