// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Hello",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .executable(name: "Hello", targets: ["Hello"])
  ],
  dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "4.0.0")),
    .package(name: "vapor-lambda-runtime", path: "../.."),
  ],
  targets: [
    .target(name: "Hello", dependencies: [
      .product(name: "Vapor", package: "vapor"),
      .product(name: "VaporLambdaRuntime", package: "vapor-lambda-runtime"),
    ]),
  ]
)
