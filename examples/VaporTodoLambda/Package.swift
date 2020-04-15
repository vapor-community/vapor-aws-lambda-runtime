// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "VaporTodoLambda",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .executable(name: "VaporTodoLambda", targets: ["VaporTodoLambda"])
  ],
  dependencies: [
    .package(path: "../.."),
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta.3.1"),
    .package(name: "AWSSDKSwift", url: "https://github.com/swift-aws/aws-sdk-swift.git", .upToNextMajor(from: "4.4.0")),
  ],
  targets: [
    .target(name: "TodoService", dependencies: [
      .product(name: "DynamoDB", package: "AWSSDKSwift")
    ]),
    .target(name: "VaporTodoLambda", dependencies: [
      .byName(name: "TodoService"),
      .product(name: "Vapor", package: "vapor"),
      .product(name: "VaporLambdaRuntime", package: "vapor-lambda-runtime"),
    ])
  ]
)
