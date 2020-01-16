import Foundation
import Vapor
import LambdaRuntime
import Dispatch
import Base64Kit
import NIOHTTP1

public final class LambdaCommand: Command {
  
  public struct Signature: CommandSignature {
    public init() { }
  }

  /// See `Command`.
  public let signature = Signature()

  /// See `Command`.
  public var help: String {
    return "Begins serving the app over HTTP."
  }

  private var signalSources: [DispatchSourceSignal]
  private var didShutdown: Bool
  private var runtime: Runtime?

  /// Create a new `ServeCommand`.
  public init() {
    self.signalSources = []
    self.didShutdown = false
  }

  /// See `Command`.
  public func run(using context: CommandContext, signature: Signature) throws {
    
    let application = context.application
    
    let handler = APIGateway.handler { (req, ctx) -> EventLoopFuture<APIGateway.Response> in
      
      ctx.logger.info("API.GatewayRequest: \(req)")
      
      let vaporRequest: Vapor.Request
      do {
        vaporRequest = try Vapor.Request(req: req, in: ctx, for: application)
      }
      catch {
        return ctx.eventLoop.makeFailedFuture(error)
      }
      
      return application.responder.respond(to: vaporRequest)
        .map { APIGateway.Response(response: $0) }
    }
    
    let runtime = try Runtime.createRuntime(
      eventLoopGroup: context.application.eventLoopGroup,
      handler: handler)
    
    let future = runtime.start()
    
    // allow the server to be stopped or waited for
    let promise = context.application.eventLoopGroup.next().makePromise(of: Void.self)
    context.application.running = .start(using: promise)

//    promise.succeed(Void)
    
//
//
//      self.running = context.application.running
//
      // setup signal sources for shutdown
      let signalQueue = DispatchQueue(label: "codes.vapor.server.shutdown")
      func makeSignalSource(_ code: Int32) {
          let source = DispatchSource.makeSignalSource(signal: code, queue: signalQueue)
          source.setEventHandler {
              print() // clear ^C
              promise.succeed(())
          }
          source.resume()
          self.signalSources.append(source)
          signal(code, SIG_IGN)
      }
      makeSignalSource(SIGTERM)
      makeSignalSource(SIGINT)
  }

  func shutdown() {
      self.didShutdown = true
//      self.running?.stop()
//      if let server = server {
//          server.shutdown()
//      }
      self.signalSources.forEach { $0.cancel() } // clear refs
      self.signalSources = []
  }
  
  deinit {
      assert(self.didShutdown, "ServeCommand did not shutdown before deinit")
  }
}
