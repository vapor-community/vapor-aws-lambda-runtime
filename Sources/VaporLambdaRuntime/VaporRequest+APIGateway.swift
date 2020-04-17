import LambdaRuntime
import NIO
import NIOHTTP1
import Vapor

extension Vapor.Request {
  
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
      method       : req.httpMethod,
      url          : Vapor.URI(path: req.path),
      version      : HTTPVersion.init(major: 1, minor: 1),
      headers      : req.headers,
      collectedBody: buffer,
      remoteAddress: nil,
      logger       : ctx.logger,
      on           : ctx.eventLoop)
    
    self.storage[APIGateway.Request] = req
  }
}

extension APIGateway.Request: Vapor.StorageKey {
    public typealias Value = APIGateway.Request
}

