// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "VaporTodoLambda",
  platforms: [
    .macOS(.v10_14)
  ],
  products: [
    .executable(name: "VaporTodoLambda", targets: ["VaporTodoLambda"])
  ],
  dependencies: [
    .package(path: "../.."),
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta.3.1"),
    .package(url: "https://github.com/swift-aws/aws-sdk-swift.git", .upToNextMajor(from: "4.0.0")),
  ],
  targets: [
    .target(
      name: "TodoService",
      dependencies: ["DynamoDB"]),
    .target(
      name: "VaporTodoLambda",
      dependencies: ["Vapor", "VaporLambdaRuntime", "TodoService"]),
  ]
)
