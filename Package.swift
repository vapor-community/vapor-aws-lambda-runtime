// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "vapor-aws-lambda-runtime",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "VaporAWSLambdaRuntime",
            targets: ["VaporAWSLambdaRuntime"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.13.0")),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from: "0.3.0")),
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/fabianfett/swift-base64-kit", .upToNextMajor(from: "0.3.0")),
    ],
    targets: [
        .target(
            name: "VaporAWSLambdaRuntime",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "Base64Kit", package: "swift-base64-kit"),
            ]
        ),
        .testTarget(
            name: "VaporAWSLambdaRuntimeTests",
            dependencies: [
                .byName(name: "VaporAWSLambdaRuntime"),
                .product(name: "AWSLambdaTesting", package: "swift-aws-lambda-runtime"),
            ]
        ),
    ]
)
