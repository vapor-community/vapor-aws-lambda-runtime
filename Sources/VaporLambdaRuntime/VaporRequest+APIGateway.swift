import LambdaRuntime
import NIO
import NIOHTTP1
import Vapor

extension Vapor.Request {
  
  public static let APIGatewayRequestKey = "Vapor.Request.VaporLambdaRuntime.APIGatewayRequest"
  
  private static let bufferAllocator = ByteBufferAllocator()
  
  convenience init(req: APIGateway.Request, in ctx: Context, for application: Application) throws {
    
    var buffer: NIO.ByteBuffer? = nil
    switch (req.body, req.isBase64Encoded) {
    case (.some(let string), true):
      let bytes = try string.base64decoded()
      buffer = Vapor.Request.bufferAllocator.buffer(capacity: bytes.count)
      buffer!.writeBytes(bytes)
  
    case (.some(let string), false):
      buffer = Vapor.Request.bufferAllocator.buffer(capacity: string.utf8.count)
      buffer!.writeString(string)
      
    case (.none, _):
      break
    }
    
    self.init(
      application  : application,
      method       : req.httpMethod.fixRawValue(),
      url          : Vapor.URI(path: req.path),
      version      : HTTPVersion.init(major: 1, minor: 1),
      headers      : req.headers,
      collectedBody: buffer,
      remoteAddress: nil,
      logger       : ctx.logger,
      on           : ctx.eventLoop)
    
    self.userInfo[Vapor.Request.APIGatewayRequestKey] = req
  }
}


private extension HTTPMethod {
  
  /// this is a workaround until https://github.com/apple/swift-nio/pull/1329 lands.
  func fixRawValue() -> HTTPMethod {
    
    switch self.rawValue {
    case "GET":
      return .GET
    case "PUT":
      return .PUT
    case "ACL":
      return .ACL
    case "HEAD":
      return .HEAD
    case "POST":
      return .POST
    case "COPY":
      return .COPY
    case "LOCK":
      return .LOCK
    case "MOVE":
      return .MOVE
    case "BIND":
      return .BIND
    case "LINK":
      return .LINK
    case "PATCH":
      return .PATCH
    case "TRACE":
      return .TRACE
    case "MKCOL":
      return .MKCOL
    case "MERGE":
      return .MERGE
    case "PURGE":
      return .PURGE
    case "NOTIFY":
      return .NOTIFY
    case "SEARCH":
      return .SEARCH
    case "UNLOCK":
      return .UNLOCK
    case "REBIND":
      return .REBIND
    case "UNBIND":
      return .UNBIND
    case "REPORT":
      return .REPORT
    case "DELETE":
      return .DELETE
    case "UNLINK":
      return .UNLINK
    case "CONNECT":
      return .CONNECT
    case "MSEARCH":
      return .MSEARCH
    case "OPTIONS":
      return .OPTIONS
    case "PROPFIND":
      return .PROPFIND
    case "CHECKOUT":
      return .CHECKOUT
    case "PROPPATCH":
      return .PROPPATCH
    case "SUBSCRIBE":
      return .SUBSCRIBE
    case "MKCALENDAR":
      return .MKCALENDAR
    case "MKACTIVITY":
      return .MKACTIVITY
    case "UNSUBSCRIBE":
      return .UNSUBSCRIBE
    case "SOURCE":
      return .SOURCE
    default:
      return .RAW(value: self.rawValue)
    }
  }
}
