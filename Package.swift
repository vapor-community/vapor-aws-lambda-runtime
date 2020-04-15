// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "vapor-lambda-runtime",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .library(
      name: "VaporLambdaRuntime",
      targets: ["VaporLambdaRuntime"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.9.0")),
    .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "4.0.0")),
    .package(url: "https://github.com/fabianfett/swift-lambda-runtime.git", .upToNextMajor(from: "0.6.0")),
    .package(url: "https://github.com/fabianfett/swift-base64-kit", .upToNextMajor(from: "0.2.0")),
  ],
  targets: [
    .target(
      name: "VaporLambdaRuntime",
      dependencies: [
        .product(name: "Vapor", package: "vapor"),
        .product(name: "LambdaRuntime", package: "swift-lambda-runtime"),
        .product(name: "NIO", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio"),
        .product(name: "Base64Kit", package: "swift-base64-kit"),
    ]),
    .testTarget(
      name: "VaporLambdaRuntimeTests",
      dependencies: ["VaporLambdaRuntime"]),
  ]
)

