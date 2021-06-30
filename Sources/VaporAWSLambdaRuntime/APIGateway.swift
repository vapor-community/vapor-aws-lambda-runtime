import AWSLambdaEvents
import AWSLambdaRuntimeCore
import ExtrasBase64
import NIO
import NIOHTTP1
import Vapor

// MARK: - Handler -

struct APIGatewayHandler: EventLoopLambdaHandler {
    typealias In = APIGateway.Request
    typealias Out = APIGateway.Response

    private let application: Application
    private let responder: Responder

    init(application: Application, responder: Responder) {
        self.application = application
        self.responder = responder
    }

    public func handle(context: Lambda.Context, event: APIGateway.Request)
        -> EventLoopFuture<APIGateway.Response>
    {
        let vaporRequest: Vapor.Request
        do {
            vaporRequest = try Vapor.Request(req: event, in: context, for: self.application)
        } catch {
            return context.eventLoop.makeFailedFuture(error)
        }

        return self.responder.respond(to: vaporRequest)
            .map { APIGateway.Response(response: $0) }
    }
}

// MARK: - Request -

extension Vapor.Request {
    private static let bufferAllocator = ByteBufferAllocator()

    convenience init(req: APIGateway.Request, in ctx: Lambda.Context, for application: Application) throws {
        var buffer: NIO.ByteBuffer?
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
        req.headers.forEach { key, value in
            nioHeaders.add(name: key, value: value)
        }

        self.init(
            application: application,
            method: NIOHTTP1.HTTPMethod(rawValue: req.httpMethod.rawValue),
            url: Vapor.URI(path: req.path),
            version: HTTPVersion(major: 1, minor: 1),
            headers: nioHeaders,
            collectedBody: buffer,
            remoteAddress: nil,
            logger: ctx.logger,
            on: ctx.eventLoop
        )

        storage[APIGateway.Request.self] = req
    }
}

extension APIGateway.Request: Vapor.StorageKey {
    public typealias Value = APIGateway.Request
}

// MARK: - Response -

extension APIGateway.Response {
    init(response: Vapor.Response) {
        var headers = [String: [String]]()
        response.headers.forEach { name, value in
            var values = headers[name] ?? [String]()
            values.append(value)
            headers[name] = values
        }

        if let string = response.body.string {
            self = APIGateway.Response(
                statusCode: AWSLambdaEvents.HTTPResponseStatus(code: response.status.code),
                multiValueHeaders: headers,
                body: string,
                isBase64Encoded: false
            )
        } else if var buffer = response.body.buffer {
            let bytes = buffer.readBytes(length: buffer.readableBytes)!
            self = APIGateway.Response(
                statusCode: AWSLambdaEvents.HTTPResponseStatus(code: response.status.code),
                multiValueHeaders: headers,
                body: String(base64Encoding: bytes),
                isBase64Encoded: true
            )
        } else {
            self = APIGateway.Response(
                statusCode: AWSLambdaEvents.HTTPResponseStatus(code: response.status.code),
                multiValueHeaders: headers
            )
        }
    }
}
