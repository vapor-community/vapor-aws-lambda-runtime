// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "vapor-lambda-runtime",
  platforms: [
    .macOS(.v10_14)
  ],
  products: [
    .library(
      name: "VaporLambdaRuntime",
      targets: ["VaporLambdaRuntime"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.9.0")),
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta.3.1"),
    .package(url: "https://github.com/fabianfett/swift-lambda-runtime.git", .upToNextMajor(from: "0.5.0")),
    .package(url: "https://github.com/fabianfett/swift-base64-kit", .upToNextMajor(from: "0.2.0")),
  ],
  targets: [
    .target(
      name: "VaporLambdaRuntime",
      dependencies: ["Vapor", "LambdaRuntime", "Base64Kit", "NIO", "NIOHTTP1"]),
    .testTarget(
      name: "VaporLambdaRuntimeTests",
      dependencies: ["VaporLambdaRuntime"]),
  ]
)

