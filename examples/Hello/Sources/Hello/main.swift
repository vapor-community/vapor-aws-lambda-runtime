import Vapor
import VaporLambdaRuntime

let app = Application()
defer { app.shutdown() }

struct Name: Codable {
  let name: String
}

struct Hello: Content {
  let hello: String
}

app.get("hello") { (req) -> Hello in
  return Hello(hello: "world")
}

app.post("hello") { req -> Hello in
  let name = try req.content.decode(Name.self)
  return Hello(hello: name.name)
}

app.commands.use(LambdaCommand(), as: "serve", isDefault: true)

try app.run()
