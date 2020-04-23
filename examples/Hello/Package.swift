// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Hello",
  platforms: [
    .macOS(.v10_15)
  ],
  dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    .package(path: "../.."),
  ],
  targets: [
    .target(name: "Hello", dependencies: ["Vapor", "VaporLambdaRuntime"]),
  ]
)
