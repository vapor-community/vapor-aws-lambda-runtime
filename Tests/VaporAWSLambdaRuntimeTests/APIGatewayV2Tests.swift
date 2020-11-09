import AWSLambdaEvents
@testable import AWSLambdaRuntimeCore
import Logging
import NIO
import Vapor
@testable import VaporAWSLambdaRuntime
import XCTest

final class APIGatewayV2Tests: XCTestCase {
    func testCreateAPIGatewayV2Response() {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer { XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully()) }
        let eventLoop = eventLoopGroup.next()
        let allocator = ByteBufferAllocator()
        let logger = Logger(label: "test")

        let body = #"{"hello": "world"}"#
        let vaporResponse = Vapor.Response(
            status: .ok,
            headers: HTTPHeaders([
                ("Content-Type", "application/json"),
            ]),
            body: .init(string: body)
        )

        let context = Lambda.Context(
            requestID: "abc123",
            traceID: AmazonHeaders.generateXRayTraceID(),
            invokedFunctionARN: "function-arn",
            deadline: .now() + .seconds(3),
            logger: logger,
            eventLoop: eventLoop,
            allocator: allocator
        )

        var response: APIGateway.V2.Response?
        XCTAssertNoThrow(response = try APIGateway.V2.Response.from(response: vaporResponse, in: context).wait())

        XCTAssertEqual(response?.body, body)
        XCTAssertEqual(response?.headers?.count, 2)
        XCTAssertEqual(response?.headers?["Content-Type"], "application/json")
        XCTAssertEqual(response?.headers?["content-length"], String(body.count))
    }
}
