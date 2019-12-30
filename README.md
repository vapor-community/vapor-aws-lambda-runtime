# vapor-lambda-runtime

Run your Vapor app on AWS Lambda. This package bridges the communication between [`swift-lambda-runtime`](https://github.com/fabianfett/swift-aws-lambda)
and the [vapor](https://github.com/vapor/vapor) framework. APIGateway requests are transformed into `Vapor.Request`s and `Vapor.Response`s are written back to the APIGateway.

This project is intended to be run using the [Swift Layer from the amazonlinux-swift project](https://fabianfett.de/amazonlinux-swift).

## Status

**Note: Currently this is nothing more than a proof of concept. Use at your own risk. I would like to hear feedback, if you played with this. Please open a GitHub issues for all open ends, you experience.**

What I have tested:

- [x] Routing
- [x] JSON Coding
- [x] Cors Middleware
- [ ] Fluent
- There are probably tons of other things that we should test. I haven't been a Vpor developer so far, so you will need to help me list the things to test.

Examples:
- [HelloWorld](examples/Hello/Sources/Hello/main.swift)
- [Super simple TodoBackend](examples/VaporTodoLambda/Sources/VaporTodoLambda/main.swift) example with DynamoDB backend (terrible code) using aws-sdk-swift

If you test anything, please open a PR so that we can document the state of afairs better. A super small example would be even better. I plan to create some integration tests with the examples.

## Usage

Add `vapor-lambda-runtime` and `vapor` as dependencies to your project. For 
this open your `Package.swift`:

```swift
  dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta.3.1"),
    .package(url: "https://github.com/fabianfett/vapor-lambda-runtime", .upToNextMajor(from: "0.1.0")),
  ]
```

Add VaporLambdaRuntime as depency to your target:

```swift
  targets: [
    .target(name: "Hello", dependencies: ["Vapor", "VaporLambdaRuntime"]),
  ]
```

Create a simple Vapor app.

```swift
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
```

Now we just need to run the vapor app. To enable running in Lambda, we 
need to change the "serve" command. Then we can start the app by calling
`app.run()`

```swift
app.commands.use(LambdaCommand(), as: "serve", isDefault: true)

try app.run()
```

## Contributing

Please feel welcome and encouraged to contribute to vapor-lambda-runtime. The current version has a long way to go before being ready for production use and help is always welcome.

If you've found a bug, have a suggestion or need help getting started, please open an Issue or a PR. If you use this package, I'd be grateful for sharing your experience.

If you like this project, I'm excited about GitHub stars. 🤓
