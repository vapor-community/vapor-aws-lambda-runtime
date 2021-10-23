//
//  File.swift
//  
//
//  Created by Ralph Küpper on 10/23/21.
//

import AWSLambdaEvents
@testable import AWSLambdaRuntimeCore
import Logging
import NIO
import Vapor
@testable import VaporAWSLambdaRuntime
import XCTest

final class SQSTests: XCTestCase {
    func testSQSRequest() throws {
        let requestdata = """
        {
          "Records": [
            {
              "messageId": "19dd0b57-b21e-4ac1-bd88-01bbb068cb78",
              "receiptHandle": "MessageReceiptHandle",
              "body": "Hello from SQS!",
              "attributes": {
                "ApproximateReceiveCount": "1",
                "SentTimestamp": "1523232000000",
                "SenderId": "123456789012",
                "ApproximateFirstReceiveTimestamp": "1523232000001"
              },
              "messageAttributes": {},
              "md5OfBody": "{{{md5_of_body}}}",
              "eventSource": "aws:sqs",
              "eventSourceARN": "arn:aws:sqs:us-east-1:123456789012:MyQueue",
              "awsRegion": "us-east-1"
            }
          ]
        }
        """
        let decoder = JSONDecoder()
        let request = try decoder.decode(SQS.Event.self, from: requestdata.data(using: .utf8)!)
        print("F: ", request)
    }

    func testCreateALBResponse() {
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

        var response: ALB.TargetGroupResponse?
        XCTAssertNoThrow(response = try ALB.TargetGroupResponse.from(response: vaporResponse, in: context).wait())

        XCTAssertEqual(response?.body, body)
        XCTAssertEqual(response?.headers?.count, 2)
        XCTAssertEqual(response?.headers?["Content-Type"], "application/json")
        XCTAssertEqual(response?.headers?["content-length"], String(body.count))
    }
}
