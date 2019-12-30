import LambdaRuntime
import Vapor
import NIO
import NIOHTTP1

extension APIGateway.Response {
  
  init(response: Vapor.Response) {
    
    if let string = response.body.string {
      self = APIGateway.Response(
        statusCode: response.status,
        headers: response.headers,
        body: string,
        isBase64Encoded: false)
    }
    else if let buffer = response.body.buffer {
      self = APIGateway.Response(
        statusCode: response.status,
        headers: response.headers,
        body: buffer.withUnsafeReadableBytes { (pointer) -> String in
          return String(base64Encoding: pointer)
        },
        isBase64Encoded: true)
    }
    else {
      self = APIGateway.Response(
        statusCode: response.status,
        headers: response.headers)
    }
  }
  
}
