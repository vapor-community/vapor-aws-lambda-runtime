//
//  File.swift
//  
//
//  Created by Ralph Küpper on 10/23/21.
//


import AWSLambdaEvents
import AWSLambdaRuntimeCore
import ExtrasBase64
import NIO
import NIOHTTP1
import Vapor

// MARK: - Handler -

struct SQSHandler: EventLoopLambdaHandler {

    typealias In = SQS.Event
    typealias Out = SQSResponse

    private let application: Application
    private let responder: Responder

    init(application: Application, responder: Responder) {
        self.application = application
        print("responder: ", responder)
        self.responder = responder
    }

    public func handle(context: Lambda.Context, event: SQS.Event)
        -> EventLoopFuture<SQSResponse>
    {
        let vaporRequest: Vapor.Request
        do {
            vaporRequest = try Vapor.Request(req: event, in: context, for: self.application)
        } catch {
            return context.eventLoop.makeFailedFuture(error)
        }

        return self.responder.respond(to: vaporRequest).flatMap { SQSResponse.from(response: $0, in: context) }
    }
}

// MARK: - Request -

extension Vapor.Request {
    private static let bufferAllocator = ByteBufferAllocator()

    convenience init(req: SQS.Event, in ctx: Lambda.Context, for application: Application) throws {
        let event = req.records.first!
        /*var buffer: NIO.ByteBuffer?
        switch (req.body, req.isBase64Encoded) {
        case (let .some(string), true):
            let bytes = try string.base64decoded()
            buffer = Vapor.Request.bufferAllocator.buffer(capacity: bytes.count)
            buffer!.writeBytes(bytes)

        case (let .some(string), false):
            buffer = Vapor.Request.bufferAllocator.buffer(capacity: string.utf8.count)
            buffer!.writeString(string)

        case (.none, _):
            break
        }

        var nioHeaders = NIOHTTP1.HTTPHeaders()
        req.headers?.forEach { key, value in
            nioHeaders.add(name: key, value: value)
        }

        /*if let cookies = req., cookies.count > 0 {
            nioHeaders.add(name: "Cookie", value: cookies.joined(separator: "; "))
        }*/

        var url: String = req.path
        if req.queryStringParameters.count > 0 {
            url += "?"
            for key in req.queryStringParameters.keys {
                // It leaves an ampersand (&) at the end, but who cares?
                url += key + "=" + (req.queryStringParameters[key] ?? "") + "&"
            }
        }*/
        var buffer: NIO.ByteBuffer?
        buffer = Vapor.Request.bufferAllocator.buffer(capacity: event.body.utf8.count)
        buffer!.writeString(event.body)
        
        let url = "/sqs"

        ctx.logger.debug("The constructed URL is: \(url)")

        self.init(
            application: application,
            method: NIOHTTP1.HTTPMethod.POST,
            url: Vapor.URI(path: url),
            version: HTTPVersion(major: 1, minor: 1),
            headers: [:],
            collectedBody: buffer,
            remoteAddress: nil,
            logger: ctx.logger,
            on: ctx.eventLoop
        )

        storage[SQS.Event] = req
    }
}

extension SQS.Event: Vapor.StorageKey {
    public typealias Value = SQS.Event
}

// MARK: - Response -

struct SQSResponse: Codable {
    public var statusCode: HTTPResponseStatus
    public var statusDescription: String?
    public var headers: HTTPHeaders?
    public var multiValueHeaders: HTTPMultiValueHeaders?
    public var body: String
    public var isBase64Encoded: Bool

    public init(
        statusCode: HTTPResponseStatus,
        statusDescription: String? = nil,
        headers: HTTPHeaders? = nil,
        multiValueHeaders: HTTPMultiValueHeaders? = nil,
        body: String = "",
        isBase64Encoded: Bool = false
    ) {
        self.statusCode = statusCode
        self.statusDescription = statusDescription
        self.headers = headers
        self.multiValueHeaders = multiValueHeaders
        self.body = body
        self.isBase64Encoded = isBase64Encoded
    }
    
    static func from(response: Vapor.Response, in context: Lambda.Context) -> EventLoopFuture<SQSResponse> {
        // Create the headers
        var headers: HTTPHeaders = [:]
        
        // Can we access the body right away?
        let string = response.body.string ?? ""
            return context.eventLoop.makeSucceededFuture(.init(
                statusCode: HTTPResponseStatus.ok,
                headers: headers,
                body: string,
                isBase64Encoded: false
            ))
    }
}
